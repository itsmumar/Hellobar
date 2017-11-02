describe PruneInactiveIntercomUsers do
  describe '#call' do
    let(:intercom_url) { 'https://api.intercom.io' }
    let(:inactivity_threshold) { 10.days }
    let(:opts) { Hash[inactivity_threshold: inactivity_threshold] }

    it 'sends delete user requests to Intercom for inactive users' do
      # create data in the past
      travel_to((inactivity_threshold - 1.day).ago)

      active = create :user, first_name: 'Free Active'
      inactive = create :user, first_name: 'Free Inactive'
      inactive_pro = create :user, first_name: 'Pro'

      inactive_with_active_site =
        create :user, first_name: 'Free Inactive With Active Site'
      inactive_with_inactive_installed_site =
        create :user, first_name: 'Free Inactive With Inactive Installed Site'

      create :site, :free_subscription, user: active
      create :site, :free_subscription, user: inactive
      create :site, :free_subscription, user: inactive_with_active_site
      create :site, :free_subscription, user: inactive_with_inactive_installed_site
      create :site, :pro, user: inactive_pro

      active_site = create :site, :free_subscription, user: inactive_with_active_site

      # installed site
      create :site, :free_subscription, :installed, user: inactive_with_inactive_installed_site

      create :bill, :pro, :paid, subscription: inactive_pro.subscriptions.first

      # verify in the present day
      travel_to((inactivity_threshold + 1.day).from_now)

      active.sites.first.touch
      active_site.touch

      expect_any_instance_of(IntercomGateway).to receive(:find_user)
        .with(inactive.id)
        .and_return inactive

      expect_any_instance_of(IntercomGateway).to receive(:delete_user)

      expect(PruneInactiveIntercomUsers.new(opts).call).to eq [inactive]
    end
  end
end
