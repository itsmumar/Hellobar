require 'integration_helper'

describe 'Admin CreditCard requests' do
  context 'when unauthenticated' do
    describe 'DELETE :destroy' do
      it 'responds with a redirect to the login page' do
        delete admin_credit_card_path 1

        expect(response).to be_a_redirect
        expect(response.location).to include 'admin/access'
      end
    end
  end

  context 'when authenticated' do
    let(:admin) { create :admin }
    let(:credit_card) { create :credit_card }

    before do
      allow_any_instance_of(AdminController)
        .to receive(:require_admin)
        .and_return admin
    end

    describe 'DELETE :destroy', :freeze do
      it 'marks credit card as deleted (sets deleted_at)' do
        expect(credit_card.token).to be_present

        delete admin_credit_card_path(credit_card)

        expect(response).to redirect_to(admin_users_path)
        expect(credit_card.reload).to be_deleted
      end
    end
  end
end
