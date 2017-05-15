require 'spec_helper'

describe DetectSiteType do
  def service(url)
    described_class.new(url)
  end

  it 'detects a weebly install', :vcr do
    expect(service('http://www.a-weebly-example-site.com/').call).to be :weebly
  end

  it 'detects a wordpress install', :vcr do
    expect(service('http://www.wordpress-example-site.io/').call).to be :wordpress
  end

  it 'detects a shopify install', :vcr do
    expect(service('http://www.calmtheham.com/').call).to be :shopify
  end

  it 'detects a squarespace install', :vcr do
    expect(service('http://blog.lyft.com/').call).to be :squarespace
  end

  it 'detects a squarespace install', :vcr do
    expect(service('http://skipjacksnauticalliving.blogspot.com/').call).to be :blogspot
  end

  context 'when cannot connect to their site' do
    it 'returns nil' do
      allow(HTTParty).to receive(:get).and_raise(SocketError)
      expect(service('http://abc.123.com/').call).to be_nil
    end
  end
end
