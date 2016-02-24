require 'spec_helper'

describe Users::ForgotEmailsController, '#create' do
  fixtures :users

  it 'queries for the email in both databases' do
    expect(User).to receive(:search_all_versions_for_email).with('email@user.com') { nil }

    post :create, email: 'email@user.com'
  end

  context 'the user is found' do
    context 'and is temporary/invited' do
      let(:temp_user) { users(:temporary) }

      it 'sets a signed permanent cookie with the email' do
        expect {
          post :create, email: temp_user.email
        }.to change{response.cookies['login_email']}.from(nil)
      end

      it 'logs a temporary user in' do
        expect {
          post :create, email: temp_user.email
        }.to change{controller.current_user}.from(nil).to(temp_user)
      end

      it 'renders the set_password template' do
        post :create, email: temp_user.email

        expect(response).to render_template(:set_password)
      end
    end

    context 'and previously registered with Google' do
      let(:user) { users(:wootie) }

      it 'redirects to the OAuth path' do
        authentication = double('authentication', provider: 'google')
        allow(user).to receive(:authentications) { [authentication] }
        allow(User).to receive(:search_all_versions_for_email) { user }

        post :create, email: user.email

        expect(response).to redirect_to("/auth/google")
      end
    end

    context 'is an email/password combo' do
      let(:user) { users(:wootie) }

      it 'renders the enter_password template' do
        post :create, email: user.email

        expect(response).to render_template(:enter_password)
      end
    end
  end

  context 'the user is not found' do
    it 'sets the error flash' do
      expect {
        post :create, email: 'this is not an email'
      }.to change{controller.flash[:error]}.from(nil)
    end

    it 'renders the new template' do
      post :create, email: 'nope nada'

      expect(response).to render_template(:new)
    end
  end
end
