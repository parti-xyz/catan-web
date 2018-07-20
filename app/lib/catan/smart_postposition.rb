module Catan
  class SmartPostposition
    def initialize(text)
      @text = text
    end
    RUELS = [%w(은 는), %w(이 가), %w(을 를), %w(과 와), %w(아 야), %w(이여 여), %w(이랑 랑)]

    def adjust(postposition)
      return postposition if postposition.try(:strip).blank?
      return postposition unless SmartPostposition::RUELS.flatten.include?(postposition)

      yes_stop_consonant, no_stop_consonant = SmartPostposition::RUELS.find do |rule|
        rule.include? postposition
      end

      choose_postposition(@text, yes_stop_consonant, no_stop_consonant)
    end

    def with!(postposition)
      return "#{@text}#{adjust(postposition)}"
    end

    private

    def smart_postposition!(text, yes_stop_consonant, no_stop_consonant)
      return text if text.try(:strip).blank?

      "#{text.strip}#{smart_postposition(text, yes_stop_consonant, no_stop_consonant)}"
    end

    def choose_postposition(text, yes_stop_consonant, no_stop_consonant)
      return text if text.try(:strip).blank?

      stop_consonant?(text) ? yes_stop_consonant : no_stop_consonant
    end

    def stop_consonant?(text)
      return false if text.try(:strip).blank?

      return (text.last.ord - 0xAC00) % 28 > 0
    end
  end
end
