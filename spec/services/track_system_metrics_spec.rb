describe TrackSystemMetrics, :freeze do
  let(:service) { TrackSystemMetrics.new }
  let(:amplitude_event) { instance_double(AmplitudeAPI::Event) }

  let(:active_sites) { 5 }
  let(:active_users) { 6 }
  let(:active_site_elements) { 7 }
  let(:active_paid_subscriptions) { 8 }
  let(:paying_users) { active_users } # uses the same `allow` stub
  let(:pending_bills_sum) { 10000 }
  let(:failed_bills_sum) { 1000 }
  let(:future_voided_bills_sum) { 3000 }
  let(:last_month_voided_bills_sum) { future_voided_bills_sum } # uses the same `allow` stub

  let(:event_properties) do
    {
      active_sites: active_sites,
      active_users: active_users,
      active_site_elements: active_site_elements,
      active_paid_subscriptions: active_paid_subscriptions,
      paying_users: paying_users,
      pending_bills_sum: pending_bills_sum,
      failed_bills_sum: failed_bills_sum,
      future_voided_bills_sum: future_voided_bills_sum,
      last_month_voided_bills_sum: last_month_voided_bills_sum
    }
  end

  let(:event_attributes) do
    {
      time: Time.current,
      event_type: TrackSystemMetrics::EVENT,
      device_id: TrackSystemMetrics::DEVICE_ID,
      event_properties: event_properties
    }
  end

  before do
    allow(Rails.env).to receive(:production?).and_return true

    allow(AmplitudeAPI::Event)
      .to receive(:new)
      .with(event_attributes)
      .and_return amplitude_event

    allow(Site).to receive_message_chain(:active, :count).and_return(active_sites)
    allow(User).to receive_message_chain(:joins, :merge, :count).and_return(active_users)
    allow(SiteElement).to receive_message_chain(:joins, :merge, :count).and_return(active_site_elements)
    allow(Subscription).to receive_message_chain(:paid, :merge, :count).and_return(active_paid_subscriptions)
    allow(Bill).to receive_message_chain(:pending, :sum).and_return(pending_bills_sum)
    allow(Bill).to receive_message_chain(:failed, :sum).and_return(failed_bills_sum)
    allow(Bill).to receive_message_chain(:voided, :where, :sum).and_return(future_voided_bills_sum)
  end

  it 'sends `system` event to amplitude' do
    expect(AmplitudeAPI).to receive(:track).with(amplitude_event)

    service.call
  end
end
