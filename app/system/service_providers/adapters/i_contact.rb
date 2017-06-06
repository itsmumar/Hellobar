module ServiceProviders
  module Adapters
    class IContact < ServiceProviders::Adapters::EmbedForm
      configure do |config|
        config.requires_embed_code = true
      end
    end
  end
end
