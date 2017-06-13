class NormalizeURI
  def self.[] url
    new(url).call
  end

  def initialize url
    @url = url
  end

  def call
    Addressable::URI.heuristic_parse url
  rescue Addressable::URI::InvalidURIError, TypeError
    nil
  end

  private

  attr_reader :url
end
