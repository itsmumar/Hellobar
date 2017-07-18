RSpec.configure do |config|
  config.before do
    allow_any_instance_of(CheckStaticScriptInstallation).to receive(:call)
  end
end
