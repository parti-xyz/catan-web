class PostCreateService
  def initialize(post:, current_user:)
    @post = post
    @current_user = current_user
  end

  def call
    @post.user = @current_user
    @post.strok_by(@current_user)
    @post.format_body

    setup_link_source(@post)
    set_current_user_to_options(@post, @current_user)
    return false unless @post.save

    @post.issue.strok_by!(@current_user, @post)
    crawling_after_creating_post
    @post.perform_mentions_async
  end

  private

  def setup_link_source(post)
    if post.survey.blank? and post.poll.blank? and post.file_sources.blank? and post.body.present?
      old_link = nil
      if post.link_source.present?
        old_link = post.link_source.url
      end

      links = find_all_a_tags(post.body)
      links_was = find_all_a_tags(post.body_was)

      first_link = links.first
      if first_link.present? and first_link['href'].present?
        if post.link_source.try(:url) != first_link['href']
          encoding_options = {
            :invalid           => :replace,  # Replace invalid byte sequences
            :undef             => :replace,  # Replace anything not defined in ASCII
            :replace           => '',        # Use a blank for those replacements
            :universal_newline => true       # Always break lines with \n
          }
          post.link_source = LinkSource.new(url: first_link['href'].encode(Encoding.find('ASCII'), encoding_options))
        end
      else
        if old_link.present?
          if !links.map{ |l| l['href'] }.include?(old_link) and links_was.map{ |l| l['href'] }.include?(old_link)
            post.link_source = nil
          else
            post.body += "<p><a href='#{old_link}'>#{old_link}</a></p>"
          end
        end
      end
    end
    post.link_source = post.link_source.unify if post.link_source.present?
  end

  def find_all_a_tags(body)
    Nokogiri::HTML.parse(body).xpath('//a[@href]').reject{ |p| all_child_nodes_are_blank?(p) }
  end

  def is_blank_node?(node)
    (node.text? && node.content.strip == '') || (node.element? && node.name == 'br')
  end

  def all_child_nodes_are_blank?(node)
    node.children.all?{ |child| is_blank_node?(child) }
  end

  def set_current_user_to_options(post, current_user)
    (post.survey.try(:options) || []).each do |option|
      option.user = current_user
    end
  end

  def crawling_after_creating_post
    if @post.link_source.try(:crawling_status).try(:not_yet?)
      CrawlingJob.perform_async(@post.link_source.id)
    end
  end
end
