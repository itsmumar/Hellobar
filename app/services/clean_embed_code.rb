class CleanEmbedCode
  def initialize(embed_code)
    @embed_code = embed_code
  end

  def call
    ascii_only replace_quotes embed_code
  end

  private

  attr_reader :embed_code

  def replace_quotes(str)
    str.tr('“”‘’', %(""''))
  end

  def ascii_only(str)
    str.gsub(/\P{ASCII}/, '')
  end
end
