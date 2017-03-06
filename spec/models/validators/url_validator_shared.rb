require 'spec_helper'

shared_examples 'an object with a valid url' do
  class WebClass
    include ActiveModel::Validations

    attr_accessor :url

    validates :url, url: true
  end

  let(:webby) { WebClass.new }

  it 'requires the url field' do
    webby.url = ''

    webby.should_not be_valid
    webby.errors[:url].should include("can't be blank")
  end

  it 'requires a url with a valid format' do
    urls = %w(
      lololol
      1234
      me@notaurl.com
      ftp://warez.dfnet.org
    )

    urls.each do |url|
      test_case = WebClass.new
      test_case.url = url

      test_case.should_not be_valid
      test_case.errors[:url].should include('is invalid')
    end
  end

  it 'accepts valid inputs' do
    urls = %w(
      http://zombo.com
      http://horse.bike
      http://madam-e.ru
      http://ec2-174-129-140-89.compute-1.amazonaws.com
    )

    urls.each do |url|
      test_case = WebClass.new
      test_case.url = url

      test_case.should be_valid
    end
  end
end
