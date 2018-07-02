module ServiceProvider::Adapters
  class VerticalResponseForm < EmbedCode
    configure do |config|
      config.requires_embed_code = true
      config.hidden = true
    end
  end
end
