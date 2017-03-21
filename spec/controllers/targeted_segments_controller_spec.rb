require 'spec_helper'

describe TargetedSegmentsController do
  let(:site) { create(:site, :with_user) }
  let(:user) { site.owners.first }

  before do
    stub_current_user(user)
  end

  describe 'with valid token' do
    let(:segment) { 'dv:mobile' }
    let(:token) { controller.send(:generate_segment_token, segment) }
    let(:mock_rule) { double('rule', id: 123, valid?: true) }

    it 'creates a rule with conditions that match the segment' do
      expect(Rule).to receive(:create_from_segment).with(site, segment).and_return(mock_rule)
      post :create, site_id: site, targeted_segment: { token: token, segment: segment }
    end

    it 'redirects to the editor to create a new element for the new rule' do
      Rule.stub(create_from_segment: mock_rule)

      post :create, site_id: site, targeted_segment: { token: token, segment: segment }

      expect(response).to redirect_to(new_site_site_element_path(site, anchor: "/settings?rule_id=#{ mock_rule.id }"))
    end

    it "redirects to sites#improve if the rule couldn't be created for some reason" do
      expect(Rule).to receive(:create_from_segment).with(site, segment).and_return(double('rule', valid?: false))

      post :create, site_id: site, targeted_segment: { token: token, segment: segment }

      expect(response).to redirect_to(site_improve_path(site))
    end
  end

  describe 'with invalid token' do
    let(:segment) { 'dv:mobile' }
    let(:token) { 'probablynotcorrect' }

    it 'does not create a rule' do
      expect(Rule).not_to receive(:create_from_segment)
      post :create, site_id: site, targeted_segment: { token: token, segment: segment }
    end

    it 'redirects to sites#improve' do
      post :create, site_id: site, targeted_segment: { token: token, segment: segment }
      expect(response).to redirect_to(site_improve_path(site))
    end
  end
end
