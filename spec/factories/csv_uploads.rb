FactoryBot.define do
  factory :csv_upload do
    contact_list

    csv do
      filename = RSpec.configuration.fixture_path.join('subscribers.csv')
      Rack::Test::UploadedFile.new(filename, 'text/csv')
    end
  end
end
