module ServiceProvider::Adapters
  class IContact < EmbedCode
    configure do |config|
      config.requires_embed_code = true
    end
  end
end
