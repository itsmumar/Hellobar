FactoryBot.define do
  factory :sender_address do
    site_id 1
    address_one "123 Maple Street"
    address_two "Unit A"
    city "San Diego"
    state "CA"
    postal_code "92103"
    country "US"
  end
end
