FactoryBot.define do
  factory :content_upgrade_settings do
    offer_headline 'offer_headline'
    disclaimer 'disclaimer'

    content_upgrade_pdf { File.new(Rails.root.join('spec', 'fixtures', 'content_upgrade.pdf')) }

    thank_you_enabled true
    thank_you_headline 'thank_you_headline'
    thank_you_subheading 'thank_you_subheading'
    thank_you_cta 'thank_you_cta'
    thank_you_url Settings.marketing_site_url
  end
end
