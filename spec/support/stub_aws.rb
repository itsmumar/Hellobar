RSpec.configure do |config|
  config.before do
    # Stub SNS
    allow_any_instance_of(Aws::SNS::Client).to receive :publish
  end
end
