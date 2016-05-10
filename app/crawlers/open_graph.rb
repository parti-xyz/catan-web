require 'mechanize'
require 'nokogiri'
require 'addressable/uri'
require 'uri'

class OpenGraph
  attr_accessor :src, :url, :type, :title, :site_name, :description, :images, :image_io, :image_width, :image_height, :image_original_filename, :metadata, :response, :original_images

  def initialize(src)
    @agent = Mechanize.new
    @agent.set_proxy ENV['CRAWLING_PROXY_HOST'], ENV['CRAWLING_PROXY_PORT'] if (Rails.env.production? or Rails.env.staging?)
    @agent.user_agent_alias = 'Windows IE 10'
    @agent.follow_meta_refresh = true
    @agent.redirect_ok = :all
    @agent.redirection_limit = 5
    @agent.gzip_enabled = false
    @agent.request_headers = { 'accept-language' => 'ko-KR,ko;q=0.8,en-US;q=0.6,en;q=0.4' }

    @src = src
    @doc = nil
    @images = []
    @image_io = nil
    @image_width = 0
    @image_height = 0
    @image_original_filename = nil
    @metadata = {}
    parse_opengraph
    check_images_path
  end

  private
  TWITTER_PATTEN = /^http[s]?:\/\/twitter\.com\/[a-zA-Z0-9_]{1,15}\/status\/\d*\/?$/
  NAVER_BLOG_PATTEN = /^http[s]?:\/\/blog\.naver\.com\/[a-zA-Z0-9_]{1,30}\/\d*\/?$/

  def is_twitter?
    (@url || @src)=~TWITTER_PATTEN
  end

  def is_naver_blog?
    ((@url || @src)=~NAVER_BLOG_PATTEN) and naver_blog_main_frame.present?
  end

  def naver_blog_main_frame
    @doc.frame_with(id: 'mainFrame')
  end

  def parse_opengraph
    begin
      @doc = @agent.get(@src)
      fallback_encoding

      if is_twitter?
        load_from_opengraph
        load_from_page(overwrite: true)
      elsif is_naver_blog?
        @doc = naver_blog_main_frame.content
        fallback_encoding
        load_from_opengraph
        load_from_page(overwrite: false)
      else
        load_from_opengraph
        load_from_page(overwrite: false)
      end
      fallback_site_name
    rescue Exception => msg
      @title = @url = @src
      return
    end
    fetch_image_io
  end

  def fetch_image_io
    bins_with_size = []
    @images.each do |image|
      begin
        bin = @agent.get(image)
        fast_image = FastImage.new(bin.body_io, proxy: proxy_for_fast_image)
        image_size = fast_image.size
        next if image_size.nil?
        bins_with_size << [bin, fast_image]

        if image_size[0] > 200 and image_size[1] > 200
          set_image_io(bin, fast_image)
          break
        end
      rescue
      end
    end
    if @image_io.blank? and bins_with_size.present?
      bins_with_size.each do |m|
        bin = m[0]
        fast_image = m[1]
        image_size = fast_image.size
        if image_size[0] > 100 and image_size[1] > 100
          set_image_io(bin, fast_image)
          break
        end
      end
    end
  end

  def proxy_for_fast_image
    return if ENV['CRAWLING_PROXY_HOST'].blank? or ENV['CRAWLING_PROXY_PORT'].blank? or (!Rails.env.production? and !Rails.env.staging?)
    "http//:#{ENV['CRAWLING_PROXY_HOST']}:#{ENV['CRAWLING_PROXY_PORT']}"
  end

  def set_image_io(bin, fast_image)
    @image_io = bin.body_io
    @image_io.class.class_eval { attr_accessor :original_filename }
    @image_original_filename = @image_io.original_filename = filename_from_bin(bin, fast_image)
    image_size = fast_image.size
    if image_size.present?
      @image_width = image_size[0]
      @image_height = image_size[1]
    end
  end

  def filename_from_bin(bin, fast_image)
    if ".#{fast_image.type}" != File.extname(bin.filename)
      "#{File.basename(bin.filename, File.extname(bin.filename))}.#{fast_image.type}"
    else
      bin.filename
    end
  end

  def fallback_encoding
    if @doc.encodings.compact.map(&:downcase).to_set.intersect?(%w(ks_c_5601-1987 euc-kr ms949).to_set)
      @doc.encoding = 'euc-kr'
    end
  end

  def load_from_opengraph
    if @doc.present? and @doc.respond_to?(:css)
      attrs_list = %w(title url type description site_name)
      @doc.css('meta').each do |m|
        if m.attribute('property') && m.attribute('property').to_s.match(/^og:(.+)$/i)
          m_content = m.attribute('content').to_s.strip
          metadata_name = m.attribute('property').to_s.gsub("og:", "")
          @metadata = add_metadata(@metadata, metadata_name, m_content)
          case metadata_name
            when *attrs_list
              self.instance_variable_set("@#{metadata_name}", m_content) unless m_content.empty?
            when "image"
              add_image(m_content)
          end
        end
      end
    end
  end

  def load_from_page(overwrite:)
    if @doc.present? and @doc.respond_to?(:xpath)
      if @title.to_s.empty? or overwrite
        if @doc.title.present?
          @title = @doc.title
        elsif @doc.xpath("//head//title").size > 0
          @title = @doc.xpath("//head//title").first.text.to_s.strip
        end
      end

      @url = @src if @url.to_s.empty?

      if (@description.to_s.empty? or overwrite) && description_meta = @doc.xpath("//head//meta[@name='description']").first
        @description = description_meta.attribute("content").to_s.strip
      end

      if @description.to_s.empty?
        @description = fetch_first_text(@doc)
      end

      fetch_images(@doc, "//head//link[@rel='image_src']", "href") if @images.empty?
      fetch_images(@doc, "//img", "src") if @images.empty?
    end
  end

  def fallback_site_name
    @site_name ||= Addressable::URI.parse(@url).host
  end

  def check_images_path
    @original_images = @images.dup
    uri = Addressable::URI.parse(@src)
    imgs = @images.dup
    @images = []
    imgs.each do |img|
      if Addressable::URI.parse(img).host.nil?
        full_path = uri.join(img).to_s
        add_image(full_path)
      else
        add_image(img)
      end
    end
  end

  def add_image(image_url)
    @images << image_url unless @images.include?(image_url) || image_url.to_s.empty?
  end

  def fetch_images(doc, xpath_str, attr)
    doc.xpath(xpath_str).each do |link|
      add_image(link.attribute(attr).to_s.strip)
    end
  end

  def fetch_first_text(doc)
    doc.xpath('//p').each do |p|
      s = p.text.to_s.strip
      return s if s.length > 20
    end
    return ''
  end

  def add_metadata(metadata_container, path, content)
    path_elements = path.split(':')
    if path_elements.size > 1
      current_element = path_elements.delete_at(0)
      path = path_elements.join(':')
      if metadata_container[current_element.to_sym]
        path_pointer = metadata_container[current_element.to_sym].last
        index_count = metadata_container[current_element.to_sym].size
        metadata_container[current_element.to_sym][index_count - 1] = add_metadata(path_pointer, path, content)
        metadata_container
      else
        metadata_container[current_element.to_sym] = []
        metadata_container[current_element.to_sym] << add_metadata({}, path, content)
        metadata_container
      end
    else
      metadata_container[path.to_sym] ||= []
      metadata_container[path.to_sym] << {'_value'.to_sym => content}
      metadata_container
    end
  end
end
