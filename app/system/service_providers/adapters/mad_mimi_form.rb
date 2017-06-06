module ServiceProviders
  module Adapters
    class MadMimiForm < ServiceProviders::Adapters::EmbedForm
      configure do |config|
        config.requires_embed_code = true
        config.disabled = true
      end
    end
  end
end
