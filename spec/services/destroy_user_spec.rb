describe DestroyUser do
  let!(:user) { create :user }
  let!(:credit_card) { create :credit_card, user: user }
  let!(:sites) { create_list :site, 2, user: user }
  let(:destroy_user) { DestroyUser.new(user) }

  before do
    stub_cyber_source :purchase

    allow_any_instance_of(StaticScript).to receive(:destroy)

    sites.each do |site|
      ChangeSubscription.new(site, { subscription: 'pro' }, credit_card).call
    end
  end

  describe '#call' do
    it 'downgrades subscriptions' do
      expect(sites.flat_map(&:subscriptions))
        .to match_array [instance_of(Subscription::Pro), instance_of(Subscription::Pro)]

      destroy_user.call

      subscriptions = sites.flat_map do |site|
        site.subscriptions.with_deleted
      end

      expect(subscriptions).to match_array [
        instance_of(Subscription::Pro),
        instance_of(Subscription::Pro),
        instance_of(Subscription::Free),
        instance_of(Subscription::Free)
      ]
    end

    it 'soft-deletes subscriptions' do
      current_subscriptions = sites.flat_map(&:current_subscription)

      destroy_user.call

      current_subscriptions.each do |subscription|
        expect(subscription.reload).to be_deleted
      end
    end

    it 'destroys credit cards' do
      expect { destroy_user.call }
        .to change(user.credit_cards, :count).to 0

      CreditCard.unscoped do
        expect(user.credit_cards.pluck(:token)).to eql [nil]
      end
    end

    it 'destroys sites which user owns' do
      expect { destroy_user.call }
        .to change(user.sites, :count).to 0
    end

    it 'destroys the user' do
      expect { destroy_user.call }
        .to change(User, :count).by(-1)
    end

    it 'sets status to deleted' do
      destroy_user.call
      expect(User.with_deleted.last.status).to eql User::DELETED
    end

    context 'when site has other users' do
      let!(:other_user) { create :user }
      let!(:membership) do
        create :site_membership, role: 'admin', site: sites.first, user: other_user
      end

      it 'remove user from site memberships' do
        expect { destroy_user.call }
          .to change(user.site_memberships, :count).to 0
      end

      it 'does not delete site with other users' do
        expect { destroy_user.call }
          .to change(Site, :count).by(-1)
        expect(Site.last.users).to match_array [other_user]
      end

      it 'promotes other user to owner' do
        expect { destroy_user.call }
          .to change { membership.reload.role }
          .from('admin').to('owner')
      end
    end
  end
end
