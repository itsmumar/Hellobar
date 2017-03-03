module Cleaners
end

module Cleaners::EmbedCode
  def clean_embed_code(embed_code)
    clean embed_code, :standard_quotes, :ascii_only
  end

  protected

  # Args:
  # embed_code, method_to_call1, method_to_call2, etc.
  def clean(*args)
    args.inject do |cleaned, method|
      self.send(method, cleaned) # On first run thru block, cleaned = embed_code
    end
  end

  private

  def standard_quotes(str)
    str.tr('“”‘’', %{""''})
  end

  def ascii_only(str)
    str.gsub(/\P{ASCII}/, '')
  end
end
