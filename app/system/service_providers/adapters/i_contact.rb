module ServiceProviders
  module Adapters
    class IContact < EmbedForm
      configure do |config|
        config.requires_embed_code = true
      end
    end
  end
end
