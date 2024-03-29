describe Settings do
  it 'cannot be instantiated' do
    expect { Settings.new }.to raise_exception NoMethodError
  end

  it 'is a proxy to Rails.application.secrets' do
    expect(Settings.secret_key_base).to eql Rails.application.secrets.secret_key_base
  end
end
