module AutoLinkableBody
  extend ActiveSupport::Concern

  def format_body(force = false)
    if self.try(:is_html_body) == 'false' or force
      self.body = ApplicationController.helpers.simple_format(ERB::Util.h(self.body), {}, sanitize: false)
    end

    self.body = find_all_a_tags(body) do |links|
      links.each do |link|
        link['target'] = '_blank'
        existing = (link['class'] || "").split(/\s+/)
        existing << "auto_link"
        link['class'] = existing.uniq.join(" ")
      end
    end.to_html()

    self.body = Rinku.auto_link(self.body, :all,
        "class='auto_link' target='_blank'",
        nil)
    strip_empty_tags
  end

  def encode_url(url)
    return if url.blank?

    encoding_options = {
      :invalid           => :replace,  # Replace invalid byte sequences
      :undef             => :replace,  # Replace anything not defined in ASCII
      :replace           => '',        # Use a blank for those replacements
      :universal_newline => true       # Always break lines with \n
    }
    url.encode(Encoding.find('ASCII'), encoding_options)
  end

  private

  def find_all_a_tags(body)
    doc = Nokogiri::HTML.parse(body)
    links = doc.xpath('//a[@href]').select{ |p| LinkSource.valid_url?(encode_url(p['href'])) }.reject{ |p| all_child_nodes_are_blank?(p) }
    if block_given?
      yield links
      return doc
    else
      return links
    end
  end

  def strip_empty_tags
    doc = Nokogiri::HTML self.body
    ps = doc.xpath('/html/body').children
    first_text = -1
    last_text = 0
    ps.each_with_index do |p, i|
      next unless p.enum_for(:traverse).map.to_a.select(&:text?).map(&:text).map(&:strip).any?(&:present?)

      #found some text
      first_text = i if first_text == -1
      last_text = i
    end

    self.body = ps.slice(first_text .. last_text).to_s
  end

  def all_child_nodes_are_blank?(node)
    node.children.all?{ |child| is_blank_node?(child) }
  end

  def is_blank_node?(node)
    (node.text? && node.content.strip == '') || (node.element? && node.name == 'br')
  end
end
