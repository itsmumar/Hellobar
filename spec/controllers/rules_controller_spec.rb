require 'spec_helper'

UNPROCESSABLE_ENTITY = 422

describe RulesController do
  fixtures :rules, :sites, :conditions
  
  let(:rule) { rules(:zombo) }
  let(:site) { sites(:zombo) }

  describe 'GET :show' do
    fixtures :users

    it 'should fail when not logged in' do
      get :show, site_id: 1, id: rule
      expect(response).to be_forbidden
    end

    it 'should fail when not owner' do
      stub_current_user users(:wootie)
      get :show, site_id: 1, id: rule
      expect(response).to be_not_found
    end

    it 'should succeed when owner' do
      stub_current_user(site.owner)
      get :show, site_id: site, id: rule
      expect(response).to be_success

      json = JSON.parse(response.body)
      expect(json.keys).to match_array %w(id site_id updated_at created_at name priority match conditions)
    end
  end

  describe 'POST :create' do
    it 'should fail when not logged in' do
      post :create, site_id: 1, rule: {}
      expect(response).to be_forbidden
    end

    it 'should succeed when not logged in' do
      stub_current_user(site.owner)
      post :create, site_id: site, rule: {
        name: 'rule name',
        priority: 1
      }
      expect(response).to be_success
      
      JSON.parse(response.body).tap do |rule|
        expect(rule['site_id']).to eq site.id
        expect(rule['name']).to eq 'rule name'
        expect(rule['priority']).to eq 1
      end
    end
  end

  describe 'DELETE :destroy' do
    fixtures :users

    it 'should fail when not logged in' do
      delete :destroy, site_id: site, id: rule
      expect(response).to be_forbidden
    end

    it 'should fail when not site owner' do
      expect(site.owner).to eq users(:joey)
      stub_current_user users(:wootie)
      delete :destroy, site_id: site, id: rule
      expect(response).to be_not_found
    end

    it 'should succeed when owner' do
      stub_current_user users(:joey)
      expect do
        delete :destroy, site_id: site, id: rule
      end.to change { Rule.count }.by(-1)
      expect(response).to be_success
    end
  end

  describe 'PUT :update' do
    fixtures :users, :conditions

    it 'should fail when not logged in' do
      put :update, site_id: site, id: rule
      expect(response).to be_forbidden
    end

    it 'should fail when not site owner' do
      expect(site.owner).to eq users(:joey)

      stub_current_user users(:wootie)
      put :update, site_id: site, id: rule, rule: {}
      expect(response).to be_forbidden
    end

    describe 'succeed as owner' do
      it 'should add a new rule with conditions' do
        stub_current_user(site.owner)
        expect do
          put :update, site_id: site, id: rule, rule: {
            name: "new rule name",
            conditions_attributes: [conditions(:date_between).attributes]
          }
        end.to change { Rule.count }.by(0)
        expect(response).to be_success

        JSON.parse(response.body).tap do |rule_obj|
          expect(rule_obj['name']).to eq "new rule name"
          
          id = rule_obj['conditions'].first['id']

          expect(rule_obj['conditions']).to eq([{
            "id" => id,
            "rule_id" => rule.id,
            "segment" => "date",
            "operand" => "is between",
            "value" => {
              "start_date" => (Date.current - 1.day).strftime("%Y-%m-%d"),
              "end_date" => (Date.current + 1.day).strftime("%Y-%m-%d")
            }
          }])
        end
      end

      it 'should add a new rule with url condition' do
        stub_current_user(site.owner)
        put :update, site_id: site, id: rule, rule: {
          name: "new rule name",
          conditions_attributes: [conditions(:url_includes).attributes]
        }
        JSON.parse(response.body).tap do |rule_obj|          
          id = rule_obj['conditions'].first['id']
          expect(rule_obj['conditions']).to eq([{
            "id" => id,
            "rule_id" => rule.id,
            "segment" => "url",
            "operand" => "includes",
            "value" => "/asdf"
          }])
        end
      end

      it 'should two rules at once' do
        stub_current_user(site.owner)
        put :update, site_id: site, id: rule, rule: {
          name: "new rule name",
          conditions_attributes: [conditions(:url_includes).attributes, conditions(:date_before).attributes]
        }
        JSON.parse(response.body).tap do |rule_obj|          
          segments = rule_obj['conditions'].collect {|c| c['segment'] }
          expect(segments).to match_array %w(date url)
        end
      end
    end
  end
end
