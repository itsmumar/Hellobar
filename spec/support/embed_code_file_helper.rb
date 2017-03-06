module EmbedCodeFileHelper
  def embed_code_file_for provider
    File.read("#{ Rails.root }/spec/support/embed_code/#{ provider }.html")
  end
end
