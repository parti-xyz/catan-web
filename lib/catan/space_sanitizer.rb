module Catan
  class SpaceSanitizer
    def do(html, *conditions)
      conditions = ["p", "ul", "li", "br", "a"] if conditions.empty?

      export = ::ActiveSupport::SafeBuffer.new # or just String
      process(::Nokogiri::HTML.parse(html)) do |node|
        if node.is_a?(::Nokogiri::XML::Text)
          if node.parent.is_a?(::Nokogiri::XML::Element) && match(node.parent, conditions) && export.present?
            export << " "
          end
          export << node.to_s
        end
      end
      export
    end

    private

    def match(node, conditions)
      conditions.include?(node.name.try(:downcase))
    end

    def process(node, &block)
      node.children.each do |node|
        yield node if block_given?
        if node.is_a?(::Nokogiri::XML::Element)
          process(node, &block)
        end
      end
    end
  end
end
