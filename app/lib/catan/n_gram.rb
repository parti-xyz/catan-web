module Catan
  class NGram
    attr_accessor :size, :word_separator

    def initialize(opts={})
      @min_size = opts[:min_size]||2
      @word_separator = opts[:word_separator]||" "
    end

    def parse(phrase)
      phrase = phrase.gsub(/\u00a0/, ' ')
      words = phrase.split(@word_separator)
      words.map { |w| process_word(w) }
    end

    private

    def process_word(word)
      return word if word.length < @min_size
      return word if word.start_with?("http://", "https://")

      (@min_size..word.length).map do |size|
        process(word, size)
      end.flatten
    end

    def process(word, size)
      (0..word.length - size).map do |idx|
        "#{word[idx, size]}"
      end
    end
  end
end
