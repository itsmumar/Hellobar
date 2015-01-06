require 'spec_helper'

describe IdentitiesController do
  before do
    request.env["HTTP_ACCEPT"] = 'application/json'
  end

  fixtures :all

  before do
    @identity = identities(:mailchimp)
    @identity.extra = {"metadata" => {}}
    @identity.save
  end

  describe 'GET :show' do
    it 'should return the identity' do
      stub_current_user @identity.site.users.first
      Gibbon::API.stubs(:new => double("gibbon"))
      ServiceProviders::MailChimp.any_instance.stub(:lists).and_return([])
      get :show, site_id: @identity.site.id, id: "mailchimp"
      json = JSON.parse(response.body)
      json["id"].should == @identity.id
    end

    it 'should return null when identity doesnt exist' do
      stub_current_user @identity.site.users.first
      get :show, site_id: @identity.site.id, id: "made_up_identity"
      response.body.should == "null"
    end

    it 'should return nothing when there is an error retrieving the service provider' do
      stub_current_user @identity.site.users.first
      ServiceProviders::MailChimp.should_receive(:new).and_raise(Gibbon::MailChimpError)
      get :show, site_id: @identity.site.id, id: "mailchimp"
      response.body.should == "null"
    end
  end
end
