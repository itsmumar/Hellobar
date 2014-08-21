module Cleaners
end

module Cleaners::EmbedCode
  def clean_embed_code(embed_code)
    clean embed_code, :standard_quotes, :ascii_only
  end

  protected

  def clean(*args)
    args.unshift.tap do |embed_code|
      args.each do |method|
        embed_code = method.call(embed_code)
      end
    end
  end

  private

  def standard_quotes(str)
    str.tr("“”‘’", %{""''})
  end

  def ascii_only(str)
    str.gsub(/\P{ASCII}/, '')
  end
end
