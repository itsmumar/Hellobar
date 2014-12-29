require 'spec_helper'

describe Admin::SitesController do
  fixtures :all

  before(:each) do
    @admin = admins(:joey)
    stub_current_admin(@admin)
  end

  let(:site) { sites(:zombo) }

  context 'PUT update' do
    it 'changes the subscription with the correct payment method and detail' do
      put :update, id: site.id, user_id: site.owner.id, subscription: { plan: 'ProComped', schedule: 'monthly' }
      site.reload.current_subscription.is_a?(Subscription::ProComped).should be_true
    end
  end
end
