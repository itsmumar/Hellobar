shared_examples 'an object with a valid url' do
  class WebClass
    include ActiveModel::Validations

    attr_accessor :url

    validates :url, url: true
  end

  let(:webby) { WebClass.new }

  it 'requires the url field' do
    webby.url = ''

    expect(webby).not_to be_valid
    expect(webby.errors[:url]).to include("can't be blank")
  end

  it 'requires a url with a valid format' do
    urls = %w[
      lololol
      1234
      me@notaurl.com
      ftp://warez.dfnet.org
      http://*.site.com
      http://.site.com
    ]

    urls.each do |url|
      test_case = WebClass.new
      test_case.url = url

      expect(test_case).not_to be_valid
      expect(test_case.errors[:url]).to include('is invalid')
    end
  end

  it 'accepts valid inputs' do
    urls = %w[
      http://zombo.com
      http://horse.bike
      http://madam-e.ru
      http://my_site.com
      http://ec2-174-129-140-89.compute-1.amazonaws.com
      http://xn--d1acpjx3f.xn--p1ai/%D0%BF%D0%BE%D0%B8%D1%81%D0%BA
    ]

    urls.each do |url|
      test_case = WebClass.new
      test_case.url = url

      expect(test_case).to be_valid
    end
  end
end
