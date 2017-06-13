describe NormalizeURI do
  it 'handles path-only URIs' do
    link = '/some/path'
    uri = NormalizeURI[link]

    expect(uri.domain).to be_nil
    expect(uri.path).to eq link
    expect(uri.to_s).to eq link
  end

  it 'handles missing scheme/protocol for known TLDs' do
    domain = 'google.com'
    path = '/site'
    link = "#{ domain }#{ path }"

    uri = NormalizeURI[link]

    expect(uri.domain).to eq domain
    expect(uri.path).to eq path
    expect(uri.scheme).to eq 'http'
    expect(uri.to_s).to eq "http://#{ link }"
  end

  it 'handles missing scheme/protocol for unknown TLDs' do
    domain = 'site.nonexistingtld'
    path = '/site'
    link = "#{ domain }#{ path }"

    uri = NormalizeURI[link]

    expect(uri.domain).to eq domain
    expect(uri.path).to eq path
    expect(uri.scheme).to eq 'http'
    expect(uri.to_s).to eq "http://#{ link }"
  end

  it 'handles new TLDs' do
    link = 'photo.cam'

    uri = NormalizeURI[link]

    expect(uri.domain).to eq link
  end

  it 'does not raise on incorrect URIs' do
    ['a b c', 'user@email.com', 'site .com'].each do |link|
      expect { NormalizeURI[link] }.not_to raise_exception
    end
  end

  it 'returns nil on unsuccessful normalization attempts' do
    link = 'site .com'

    uri = NormalizeURI[link]

    expect(uri).to be_nil
  end
end
