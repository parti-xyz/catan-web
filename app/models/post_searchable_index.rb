class PostSearchableIndex < ApplicationRecord
  belongs_to :post

  def reindex
    self.ngram = make_ngram
  end

  def reindex!
    update_columns(ngram: make_ngram)
  end

  def self.sanitize_search_key(key)
    return if key.blank?
    result = key.split.compact.map do |w|
      w.gsub(/[^ㄱ-ㅎ가-힣a-z0-9]/i, '')
    end.compact

    return nil if result.any? { |w| w.length < 2 }
    result.join(' ')
  end

  def self.search(key)
    sanitized_key = self.sanitize_search_key(key)
    return all if sanitized_key.blank?

    fulltext_query = sanitized_key.split.map { |w| "+(\"#{w}\")" }.join(' ')
    where("match(ngram) against (? in boolean mode)", fulltext_query)
  end

  private

  def make_ngram
    return '' if post.blank?

    max = 16777215 / 3
    [post.body, post.base_title, post.wiki.try(:body)].compact.map do |text|
      to_ngram(sanitize_html(text))
    end.flatten.uniq.join(' ').strip[0..max]
  end

  def to_ngram(data)
    @ngram ||= ::Catan::NGram.new(min_size: 2, word_separator: " ")
    @ngram.parse(data)
  end
end
