require 'integration_helper'

describe 'PaymentMethodDetails requests' do
  context 'when unauthenticated' do
    describe 'DELETE :destroy' do
      it 'responds with a redirect to the login page' do
        delete admin_payment_method_detail_path 1

        expect(response).to be_a_redirect
        expect(response.location).to include 'admin/access'
      end
    end
  end

  context 'when authenticated' do
    let(:admin) { create :admin }
    let(:payment_method) { create :payment_method, :cyber_source_credit_card }
    let(:payment_method_details) { payment_method.details.first }

    before do
      allow_any_instance_of(AdminController).to receive(:require_admin).and_return admin
    end

    describe 'DELETE :destroy', :freeze do
      it 'deletes payment method and the token associated with the details' do
        expect(payment_method_details.data['token']).to be_present

        delete admin_payment_method_detail_path payment_method_details

        expect(response).to be_a_redirect
        expect(response.redirect_url).to include admin_users_path

        expect(payment_method_details.reload.data['token']).to be_nil
        expect(payment_method.reload.deleted_at).to eql Time.current
      end
    end
  end
end
