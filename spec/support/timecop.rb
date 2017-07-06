require 'timecop'

RSpec.configure do |config|
  config.around(:each, freeze: true) do |example|
    time = example.metadata.fetch(:freeze)
    time =
      if time.eql?(true)
        Date.current
      else
        time.is_a?(Integer) ? Time.zone.at(time) : Time.zone.parse(time)
      end
    Timecop.freeze(time) do
      example.run
    end
  end
end
