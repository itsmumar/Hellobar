describe TrackSystemMetrics, :freeze do
  let(:service) { TrackSystemMetrics.new }
  let(:amplitude_event) { instance_double(AmplitudeAPI::Event) }

  let(:installed_sites) { 6 }
  let(:active_sites) { 5 }
  let(:active_users) { 9 }
  let(:active_site_elements) { 7 }
  let(:active_paid_subscriptions) { 8 }
  let(:active_paid_pro_subscriptions) { 6 }
  let(:active_paid_growth_subscriptions) { 1 }
  let(:active_paid_enterprise_subscriptions) { 1 }
  let(:active_paid_subscription_average_days) { 30.0 }
  let(:paying_users) { active_users } # uses the same `allow` stub
  let(:paying_pro_users) { 7 }
  let(:paying_growth_users) { paying_pro_users } # uses the same `allow` stub
  let(:paying_enterprise_users) { paying_pro_users } # uses the same `allow` stub
  let(:pending_bills_sum) { 10000 }
  let(:failed_bills_sum) { 1000 }
  let(:future_voided_bills_sum) { 3000 }
  let(:last_month_voided_bills_sum) { future_voided_bills_sum } # uses the same `allow` stub

  let(:event_properties) do
    {
      installed_sites: installed_sites,
      active_sites: active_sites,
      active_users: active_users,
      active_site_elements: active_site_elements,
      active_paid_subscriptions: active_paid_subscriptions,
      active_paid_pro_subscriptions: active_paid_pro_subscriptions,
      active_paid_growth_subscriptions: active_paid_growth_subscriptions,
      active_paid_enterprise_subscriptions: active_paid_enterprise_subscriptions,
      active_paid_subscription_average_days: active_paid_subscription_average_days,
      paying_users: paying_users,
      paying_pro_users: paying_pro_users,
      paying_growth_users: paying_growth_users,
      paying_enterprise_users: paying_enterprise_users,
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

    allow(Site).to receive_message_chain(:script_installed, :count).and_return(installed_sites)
    allow(Site).to receive_message_chain(:active, :count).and_return(active_sites)
    allow(User).to receive_message_chain(:joins, :merge, :count).and_return(active_users)
    allow(User).to receive_message_chain(:joins, :merge, :merge, :count).and_return(paying_pro_users)
    allow(SiteElement).to receive_message_chain(:joins, :merge, :count).and_return(active_site_elements)
    allow(Subscription).to receive_message_chain(:paid, :merge, :count).and_return(active_paid_subscriptions)
    allow(Subscription).to receive_message_chain(:paid, :pro, :merge, :count).and_return(active_paid_pro_subscriptions)
    allow(Subscription).to receive_message_chain(:paid, :growth, :merge, :count).and_return(active_paid_growth_subscriptions)
    allow(Subscription).to receive_message_chain(:paid, :enterprise, :merge, :count).and_return(active_paid_enterprise_subscriptions)
    allow(Subscription).to receive_message_chain(:paid, :merge, :average).and_return(30.days.ago.to_i)
    allow(Bill).to receive_message_chain(:pending, :sum).and_return(pending_bills_sum)
    allow(Bill).to receive_message_chain(:failed, :sum).and_return(failed_bills_sum)
    allow(Bill).to receive_message_chain(:voided, :where, :sum).and_return(future_voided_bills_sum)
  end

  it 'sends `system` event to amplitude' do
    expect(AmplitudeAPI).to receive(:track).with(amplitude_event)

    service.call
  end
end
