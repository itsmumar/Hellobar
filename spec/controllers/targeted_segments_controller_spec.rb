require 'spec_helper'

describe TargetedSegmentsController do
  fixtures :all

  let(:site) { sites(:zombo) }
  let(:user) { site.owners.first }

  before do
    stub_current_user(user)
  end

  describe 'with valid token' do
    before do
      @segment = 'dv:mobile'
      @token = controller.send(:generate_segment_token, @segment)
      @mock_rule = double('rule', id: 123, valid?: true)
    end

    it 'creates a rule with conditions that match the segment' do
      Rule.should_receive(:create_from_segment).with(site, @segment).and_return(@mock_rule)
      post :create, site_id: site, targeted_segment: {token: @token, segment: @segment}
    end

    it 'redirects to the editor to create a new element for the new rule' do
      Rule.stub(create_from_segment: @mock_rule)

      post :create, site_id: site, targeted_segment: {token: @token, segment: @segment}

      response.should redirect_to(new_site_site_element_path(site, :anchor => "/settings?rule_id=#{@mock_rule.id}"))
    end

    it "redirects to sites#improve if the rule couldn't be created for some reason" do
      Rule.should_receive(:create_from_segment).with(site, @segment).and_return(double('rule', :valid? => false))

      post :create, site_id: site, targeted_segment: {token: @token, segment: @segment}

      response.should redirect_to(site_improve_path(site))
    end
  end

  describe 'with invalid token' do
    before do
      @segment = 'dv:mobile'
      @token = 'probablynotcorrect'
    end

    it 'does not create a rule' do
      Rule.should_not_receive(:create_from_segment)
      post :create, site_id: site, targeted_segment: {token: @token, segment: @segment}
    end

    it 'redirects to sites#improve' do
      post :create, site_id: site, targeted_segment: {token: @token, segment: @segment}
      response.should redirect_to(site_improve_path(site))
    end
  end
end
