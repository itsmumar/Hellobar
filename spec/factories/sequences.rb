FactoryGirl.define do
  sequence :random_uniq_url do
    'http://url.net'.split('.').insert(1, "-#{ (0...8).map { 65.+(rand(26)).chr }.join.downcase }").insert(2, '.').join
  end

  sequence(:email) { |i| "user#{ i }@hellobar.com" }
end
