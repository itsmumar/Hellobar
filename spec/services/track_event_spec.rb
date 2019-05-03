describe TrackEvent do
  before { allow(Rails.env).to receive(:production?).and_return true }
  let(:event) { :foo_bar_event }
  let(:params) { Hash[foo: 'foo', bar: 'bar'] }
  let(:service) { TrackEvent.new(event, **params) }

  it 'does not enqueue SendEventToIntercomJob' do
    service.call
    expect(SendEventToIntercomJob)
      .not_to have_been_enqueued
      .with(event.to_s, params)
  end

  it 'enqueues SendEventToAmplitudeJob' do
    service.call
    expect(SendEventToAmplitudeJob)
      .to have_been_enqueued
      .with(event.to_s, params)
  end

  context 'when on edge' do
    before { allow(Rails.env).to receive(:edge?).and_return true }
    before { allow(Rails.env).to receive(:production?).and_return false }

    it 'does not enqueue SendEventToIntercomJob' do
      service.call
      expect(SendEventToIntercomJob)
        .not_to have_been_enqueued
        .with(event.to_s, params)
    end

    it 'does not enqueue SendEventToAmplitudeJob' do
      service.call
      expect(SendEventToAmplitudeJob).not_to have_been_enqueued
    end

    it 'does not enqueue SendEventToProfitwellJob' do
      service.call
      expect(SendEventToProfitwellJob).not_to have_been_enqueued
    end
  end

  context 'when event is :triggered_upgrade_account' do
    let(:event) { :upgrade_account_triggered }

    it 'enqueues SendEventToAmplitudeJob' do
      service.trigger
      expect(SendEventToAmplitudeJob)
        .to have_been_enqueued
        .with(event.to_s, params)
    end
  end

  context 'when event is :triggered_payment_checkout' do
    let(:event) { :payment_checkout_triggered }

    it 'enqueues SendEventToAmplitudeJob' do
      service.trigger
      expect(SendEventToAmplitudeJob)
        .to have_been_enqueued
        .with(event.to_s, params)
    end
  end

  context 'when event is :upgraded_subscription' do
    let(:event) { :upgraded_subscription }

    it 'enqueues SendEventToProfitwellJob' do
      service.call
      expect(SendEventToProfitwellJob)
        .to have_been_enqueued
        .with(event.to_s, params)
    end
  end

  context 'when event is :downgraded_subscription' do
    let(:event) { :downgraded_subscription }

    it 'enqueues SendEventToProfitwellJob' do
      service.call
      expect(SendEventToProfitwellJob)
        .to have_been_enqueued
        .with(event.to_s, params)
    end
  end
end
