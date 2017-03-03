require 'spec_helper'

describe GoogleAnalytics, '#find_account_by_url' do
  it 'returns the account that contains the current site url' do
    service = GoogleAnalytics.new
    account = double('item', web_properties: [double('property', website_url: 'http://www.website.com')])
    response = double('response', items: [account])
    analytics = double('analytics', list_account_summaries: response)
    allow(service).to receive(:analytics) { analytics }

    expect(service.find_account_by_url('http://www.website.com')).to eql(account)
  end

  it 'returns nil if there are no accounts for this user' do
    service = GoogleAnalytics.new
    response = double('response', items: [])
    analytics = double('analytics', list_account_summaries: response)
    allow(service).to receive(:analytics) { analytics }

    expect(service.find_account_by_url('site.com')).to eql(nil)
  end

  it 'returns nil if no accounts contain the current site url' do
    service = GoogleAnalytics.new
    account = double('item', web_properties: [double('property', website_url: 'http://www.website.com')])
    response = double('response', items: [account])
    analytics = double('analytics', list_account_summaries: response)
    allow(service).to receive(:analytics) { analytics }

    expect(service.find_account_by_url('www.site.com')).to eql(nil)
  end

  it 'does not raise an error if the web property has a nil website_url' do
    service = GoogleAnalytics.new
    account = double('item', web_properties: [double('property', website_url: nil)])
    response = double('response', items: [account])
    analytics = double('analytics', list_account_summaries: response)
    allow(service).to receive(:analytics) { analytics }

    expect{service.find_account_by_url('www.site.com')}.to_not raise_error
  end

  it "returns nil if the user doesn't have a Google Analytics account" do
    service = GoogleAnalytics.new
    allow(service.analytics).to receive(:list_account_summaries).and_raise(Google::Apis::ClientError.new('insufficientPermissions: User does not have any Google Analytics account.'))

    expect(service.find_account_by_url('www.site.com')).to eql(nil)
  end

  it 'handles unexpected errors' do
    class Google::Apis::UnExpectedError < Google::Apis::Error
    end
    error = Google::Apis::UnExpectedError.new('Un-handled Error')

    service = GoogleAnalytics.new
    allow(service.analytics).to receive(:list_account_summaries).and_raise(error)

    expect(Rails.logger).to receive(:warn).with(error.inspect).once
    expect(Rails.logger).to receive(:warn).with('Un-handled Error').once
    expect{service.find_account_by_url('www.site.com')}.to raise_error(Google::Apis::UnExpectedError)
  end
end

describe GoogleAnalytics, '#get_latest_pageviews' do
  it 'returns nil if we could not find the corresponding site' do
    service = GoogleAnalytics.new
    allow(service).to receive(:find_account_by_url) { nil }

    expect(service.get_latest_pageviews('url.com')).to eql(nil)
  end

  it 'returns the pageviews for the past 30 days for the specified site' do
    service = GoogleAnalytics.new
    rows = double('rows', rows: [['9001']])
    analytics = double('analytics', get_ga_data: rows)
    profile = double('profile', id: 1)
    property = double('web property', website_url: 'http://www.site.com', profiles: [profile])
    account = double('account', web_properties: [property])
    allow(service).to receive(:find_account_by_url) { account }
    allow(service).to receive(:analytics) { analytics }

    expect(service.get_latest_pageviews('http://www.site.com')).to eql(9_001)
  end

  it 'does not raise an error if the web property has a nil website_url' do
    service = GoogleAnalytics.new
    rows = double('rows', rows: [['9001']])
    analytics = double('analytics', get_ga_data: rows)
    profile = double('profile', id: 1)
    property_without_url = double('web property', website_url: nil, profiles: [profile])
    property = double('web property', website_url: 'http://www.site.com', profiles: [profile])
    account = double('account', web_properties: [property_without_url, property])
    allow(service).to receive(:find_account_by_url) { account }
    allow(service).to receive(:analytics) { analytics }

    expect{service.get_latest_pageviews('http://www.site.com')}.to_not raise_error
  end

  it 'does not raise an error if google analytics returns nil rows' do
    service = GoogleAnalytics.new
    rows = double('rows', rows: nil)
    analytics = double('analytics', get_ga_data: rows)
    profile = double('profile', id: 1)
    property_without_url = double('web property', website_url: nil, profiles: [profile])
    property = double('web property', website_url: 'http://www.site.com', profiles: [profile])
    account = double('account', web_properties: [property_without_url, property])
    allow(service).to receive(:find_account_by_url) { account }
    allow(service).to receive(:analytics) { analytics }

    expect{service.get_latest_pageviews('http://www.site.com')}.to_not raise_error
  end
end
