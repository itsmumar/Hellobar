require 'timecop'

RSpec.configure do |config|
  config.around(:each, freeze: true) do |example|
    time = example.metadata.fetch(:freeze)
    time =
      if time.eql?(true)
        Date.current
      elsif time.is_a?(Integer)
        Time.zone.at(time)
      elsif time.is_a?(String)
        Time.zone.parse(time)
      else
        time
      end
    Timecop.freeze(time) do
      example.run
    end
  end
end
