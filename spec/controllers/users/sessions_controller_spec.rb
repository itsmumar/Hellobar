require 'spec_helper'

describe Users::SessionsController do
  fixtures :all

  before(:each) do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    @wordpress_user = OpenStruct.new(id: 123)
  end

  describe 'POST find_email' do
    render_views

    context 'the user email is not found' do
      it 'redirects to the new_user_session_path if the email doesnt exist' do
        post :find_email, user: { email: 'hello@email.com' }

        expect(response).to redirect_to(new_user_session_path)
      end

      it 'deletes the login_email cookie if the email doesnt exist' do
        request.cookies['login_email'] = 'hello@email.com'

        post :find_email, user: { email: 'hello@email.com' }

        expect(response.cookies['login_email']).to be_nil
      end
    end

    context 'the user email is found' do
      it 'renders the set_password page for temporary users' do
        user = User.new status: User::TEMPORARY_STATUS
        allow(User).to receive(:search_all_versions_for_email) { user }

        post :find_email, user: { email: 'hello@email.com' }

        expect(response).to render_template('users/forgot_emails/set_password')
      end

      it 'redirects users to login via OAuth if they have a Google account' do
        google_auth = double('authentication', provider: 'google')
        user = double('user', status: 'active', wordpress_user?: false, authentications: [google_auth])
        allow(User).to receive(:search_all_versions_for_email) { user }

        post :find_email, user: { email: 'hello@email.com' }

        expect(response).to redirect_to('/auth/google')
      end

      it 'renders the find_email template if a v1 Wordpress user' do
        user = double('wordpress user', wordpress_user?: true, email: 'email@email.com', password: nil)
        allow(User).to receive(:search_all_versions_for_email) { user }

        post :find_email, user: { email: 'hello@email.com' }

        expect(response).to render_template('users/sessions/find_email')
      end

      it 'renders the find_email template if an email/password user' do
        allow(User).to receive(:search_all_versions_for_email) { User.new }

        post :find_email, user: { email: 'hello@email.com' }

        expect(response).to render_template('users/sessions/find_email')
      end
    end
  end

  describe 'POST create' do
    it 'logs in a user with valid params' do
      controller.current_user.should be_nil
      post :create, user: { email: 'joey@polymathic.me', password: 'password' }
      controller.current_user.should == users(:joey)
    end

    it 'redirects oauth users to their respective oauth path' do
      users(:joey).authentications.create(provider: 'google_oauth2', uid: '123')
      post :create, user: { email: 'joey@polymathic.me', password: 'some incorrect pass' }
      response.should redirect_to('/auth/google_oauth2')
    end

    it 'redirects 1.0 users to migration wizard if the correct password is used' do
      pending 'until migration wizard is made available to all users'

      email = 'user@website.com'
      password = 'asdfasdf'

      Hello::WordpressUser.should_receive(:email_exists?).with(email).and_return(true)
      Hello::WordpressUser.should_receive(:authenticate).with(email, password).and_return(@wordpress_user)

      post :create, user: { email: email, password: password }

      response.should redirect_to(new_user_migration_path)
    end

    it 'asks 1.0 users to reauthenticate if their password is wrong' do
      pending 'until migration wizard is made available to all users'

      email = 'user@website.com'
      password = 'asdfasdf'

      Hello::WordpressUser.should_receive(:email_exists?).with(email).and_return(true)
      Hello::WordpressUser.should_receive(:authenticate).with(email, password).and_return(nil)

      post :create, user: { email: email, password: password }

      flash.now[:alert].should =~ /Invalid/
      response.should render_template('users/sessions/new')
    end
  end
end
