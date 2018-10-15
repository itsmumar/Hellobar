describe CreditCardsController do
  let(:payment_form_params) { create :payment_form_params }
  let(:payment_form) { create :payment_form, params: payment_form_params }
  let(:params) { { credit_card: payment_form_params } }

  before do
    @user = create(:user)
    stub_current_user(@user)
    @site_element = create(:site_element)
    @site_element.site.users << @user
    stub_handle_overage(@site_element.site, 100, 99)
  end

  describe 'POST #create' do
    before do
      stub_cyber_source :store, :purchase
    end
    context 'when plan is selected' do
      before { params[:credit_card][:plan] = 'elite-monthly' }
      before { params[:site_id] = @user.sites.first.id }
      it 'should redirect the user to new_site_element_path' do
        post :create, params
        expect(response.status).to redirect_to(new_site_site_element_path(@user.sites.first))
      end
    end

    context 'when plan is not selected' do
      before { params[:site_id] = @user.sites.first.id }
      it 'should redirect the user to what ever url he is eventually going to' do
        post :create, params
        expect(response.status).to redirect_to(controller.after_sign_in_path_for(@user))
      end
    end
  end
end
