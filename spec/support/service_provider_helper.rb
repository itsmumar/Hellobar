Dir[Rails.root.join('app', 'system', 'service_providers', '**', '*.rb')].each(&method(:require))

module ServiceProviderHelper
  def allow_requests(method, *requests)
    requests.each do |request|
      allow_request(method, request)
    end
  end

  def allow_request(method, request, body: {})
    url = url_for_request(request)
    response = response_for(method, request)

    if block_given?
      yield stub_request(method, url).with(body: body).to_return(response)
    else
      stub_request(method, url).with(body: body).to_return(response)
    end
  end

  def adapter_name
    described_class.name.demodulize.underscore
  end

  def response_fixture_for(method, request)
    txt = Rails.root.join("spec/fixtures/service_providers/#{ adapter_name }/#{ request }.#{ method }.txt")
    json = Rails.root.join("spec/fixtures/service_providers/#{ adapter_name }/#{ request }.json")
    xml = Rails.root.join("spec/fixtures/service_providers/#{ adapter_name }/#{ request }.xml")

    [txt, json, xml].find(&:exist?) || raise("place a file to spec/fixtures/service_providers/#{ adapter_name }/#{ request }.{json,xml,txt}, method: #{ method }")
  end

  def response_for(method, request)
    fixture = response_fixture_for(method, request)
    case fixture.extname
    when '.txt'
      fixture.read
    when '.json'
      { body: fixture.read, headers: { 'Content-Type': 'application/json' } }
    when '.xml'
      { body: fixture.read, headers: { 'Content-Type': 'text/xml' } }
    end
  end

  def url_for_request(request)
    Addressable::Template.new defined_urls.fetch(request)
  end

  def content_type_for(response)
    response
  end
end
