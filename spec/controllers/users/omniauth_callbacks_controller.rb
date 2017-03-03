require 'spec_helper'

describe Users::OmniauthCallbacksController do
  fixtures :all

  before(:each) do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'POST google_oauth2' do
    it 'redirects to new_site_path with a URL param if the user exists' do
      user = users(:wootie)

      request.env['omniauth.auth'] = { 'info' => { 'email' => user.email }, 'uid' => 'abc123',
        'provider' => 'google_oauth2' }
      session[:new_site_url] = 'www.test.com'
      post :google_oauth2

      response.should redirect_to(new_site_path(url: session[:new_site_url]))
    end

    it 'redirects to continue_create_site_path if the user is registering and new_site_url session is present' do
      request.env['omniauth.auth'] = { 'info' => { 'email' => 'test@test.com' }, 'uid' => 'abc123',
        'provider' => 'google_oauth2' }
      session[:new_site_url] = 'www.test.com'
      post :google_oauth2

      response.should redirect_to(continue_create_site_path)
    end

    it 'redirects to the default path if site url is not set' do
      request.env['omniauth.auth'] = { 'info' => { 'email' => 'test@test.com' }, 'uid' => 'abc123',
        'provider' => 'google_oauth2' }
      post :google_oauth2
      response.should redirect_to(new_site_path)
    end
  end
end
