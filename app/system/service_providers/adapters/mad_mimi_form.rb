module ServiceProviders
  module Adapters
    class MadMimiForm < EmbedForm
      configure do |config|
        config.requires_embed_code = true
        config.disabled = true
      end
    end
  end
end
