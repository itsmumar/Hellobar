describe RegistrationsController do
  let(:params) do
    Hash[email: 'email@example.com', password: 'password', site_url: 'wwww.abcd.com', accept_terms_and_conditions: 'true']
  end

  describe 'POST #create' do
    context 'when plan is selected' do
      before { params[:plan] = 'elite-monthly' }
      it 'should redirect the user to subscribe and take credit card info' do
        post :create, registration_form: params, signup_with_email: 'true'
        expect(response.status).to redirect_to('/subscribe/elite-monthly')
      end
    end

    context 'when plan is not selected' do
      it 'should redirect the user to new_site_element_path' do
        post :create, registration_form: params, signup_with_email: 'true'
        expect(response.status).to redirect_to(new_site_site_element_path(controller.current_user.sites.first))
      end
    end
  end
end
