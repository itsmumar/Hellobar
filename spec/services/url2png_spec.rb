describe Url2png do
  let(:options) { Hash[url: 'http://example.com', viewport: '320x568'] }
  let(:service) { Url2png.new(options) }
  let(:url) { service.call }

  before do
    allow(Settings).to receive(:url2png_api_key).and_return('PXXX')
    allow(Settings).to receive(:url2png_api_secret).and_return('SXXX')
  end

  describe '#call' do
    it 'returns URL to url2png.com with all params' do
      expect(url).to eql 'api.url2png.com/v6/PXXX/' \
                         'a39f2dd2023bc3c175a8f010b5808ade/png/' \
                         '?custom_css_url=http%3A%2F%2Flocalhost' \
                         '%2Fstylesheets%2Fhide_bar.css&' \
                         'ttl=604800&url=http%3A%2F%2Fexample.com&viewport=320x568'
    end

    context 'without viewport' do
      let(:options) { Hash[url: 'http://example.com'] }

      it 'does not include viewport param' do
        expect(url).not_to include 'viewport'
      end
    end

    context 'with include_protocol: true' do
      let(:options) { Hash[url: 'http://example.com', include_protocol: true] }

      it 'does not include viewport param' do
        expect(url).to start_with 'https://api.url2png.com'
      end
    end
  end
end
