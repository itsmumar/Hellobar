module ServiceProvider::Adapters
  class Hellobar < Base
    configure do |config|
      config.hidden = true
    end

    def subscribe(_list_id, _params)
      # do nothing
    end
  end
end
