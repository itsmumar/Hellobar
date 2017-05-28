module ServiceProviderHelper
  extend ActiveSupport::Concern

  class_methods do
    def define_urls(urls)
      let(:defined_urls) { urls }
    end

    def allow_request(method, request, body: {})
      before do
        url = url_for_request(request)
        response = response_for(method, request)

        if block_given?
          yield stub_request(method, url).with(body: body).to_return(response)
        else
          stub_request(method, url).with(body: body).to_return(response)
        end
      end
    end

    def allow_requests(method, *requests)
      requests.each do |request|
        allow_request(method, request)
      end
    end
  end

  def adapter_name
    adapter.class.name.demodulize.underscore
  end

  def response_fixture_for(method, request)
    txt = Rails.root.join("spec/fixtures/service_providers/#{ adapter_name }/#{ request }.#{ method }.txt")
    json = Rails.root.join("spec/fixtures/service_providers/#{ adapter_name }/#{ request }.json")
    xml = Rails.root.join("spec/fixtures/service_providers/#{ adapter_name }/#{ request }.xml")
    [json, xml, txt].find(&:exist?)
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
