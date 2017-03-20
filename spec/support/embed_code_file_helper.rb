module EmbedCodeFileHelper
  def embed_code_file_for provider
    Rails.root.join('spec', 'support', 'embed_code', "#{ provider }.html").read
  end
end
