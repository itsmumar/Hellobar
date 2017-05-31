FactoryGirl.define do
  factory :image_upload do
    site
    version 1

    trait :with_valid_image do
      image { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'images', 'coupon.png'), 'image/png') }
    end

    trait :with_text do
      image { Rack::Test::UploadedFile.new(Rails.root.join('README.md'), 'test/plain') }
    end
  end
end
