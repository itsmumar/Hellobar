require 'spec_helper'

describe ServiceProviders::Webhook, 'subscribe' do
  let(:contact_list) { build(:contact_list, data: { 'webhook_url' => url, 'webhook_method' => 'post' }) }
  let(:url) { 'http://hellobar.com' }

  it 'initializes the client with the webhook_url' do
    webhook = ServiceProviders::Webhook.new(contact_list: contact_list)
    client = Faraday.new
    allow(client).to receive(:post)

    expect(Faraday).to receive(:new).with(url: url) { client }

    webhook.subscribe(nil, 'email@email.com')
  end

  it 'sends a GET request when webhook_method is get' do
    contact_list.data['webhook_method'] = 'get'
    webhook = ServiceProviders::Webhook.new(contact_list: contact_list)
    client = Faraday.new
    allow(Faraday).to receive(:new) { client }

    expect(client).to receive(:get)

    webhook.subscribe(nil, 'email@email.com')
  end

  it 'sends a POST request when webhook_method is post' do
    webhook = ServiceProviders::Webhook.new(contact_list: contact_list)
    client = Faraday.new
    allow(Faraday).to receive(:new) { client }

    expect(client).to receive(:post)

    webhook.subscribe(nil, 'email@email.com')
  end

  it 'sends the email and name params' do
    webhook = ServiceProviders::Webhook.new(contact_list: contact_list)
    client = Faraday.new
    request = double('request')
    allow(Faraday).to receive(:new) { client }
    allow(client).to receive(:post).and_yield(request)

    expect(request).to receive(:body=).with(hash_including(email: 'email@email.com', name: 'name'))
    webhook.subscribe(nil, 'email@email.com', 'name')
  end
end

describe ServiceProviders::Webhook, 'batch_subscribe' do
  let(:contact_list) { build(:contact_list, data: { 'webhook_url' => url, 'webhook_method' => 'post' }) }
  let(:url) { 'http://hellobar.com' }

  it 'subscribes in batches' do
    webhook = ServiceProviders::Webhook.new(contact_list: contact_list)
    subscribers = [
      { email: 'email1@email.com' },
      { email: 'email2@email.com' },
      { email: 'email3@email.com' }
    ]

    expect(webhook).to receive(:subscribe).exactly(3).times

    webhook.batch_subscribe(nil, subscribers)
  end
end
