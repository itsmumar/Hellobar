module ServiceProviderHelper
  extend ActiveSupport::Concern

  class_methods do
    def define_urls(urls)
      let(:defined_urls) { urls }
    end

    def allow_request(method, request, body: {})
      before do
        url = url_for_request(request)

        response =
          if method == :get
            { body: response_body_for(request), headers: { 'Content-Type': 'application/json' } }
          else
            response_for(method, request)
          end

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

  def response_body_for(request)
    File.read Rails.root.join("spec/fixtures/service_providers/#{ adapter_name }/#{ request }.json")
  end

  def response_for(method, request)
    File.new Rails.root.join("spec/fixtures/service_providers/#{ adapter_name }/#{ request }.#{ method }.txt")
  end

  def url_for_request(request)
    Addressable::Template.new defined_urls.fetch(request)
  end
end
