require 'spec_helper'

UNAUTHORIZED = '401'

describe RulesController do
  before do
    request.env['HTTP_ACCEPT'] = 'application/json'
  end

  fixtures :all

  let(:rule) { rules(:pro) }
  let(:site) { sites(:pro_site) }

  describe 'GET :show' do
    it 'should fail when not logged in' do
      get :show, site_id: 1, id: rule
      expect(response.code).to eq UNAUTHORIZED
    end

    it 'should fail when not owner' do
      stub_current_user users(:wootie)
      get :show, site_id: 1, id: rule
      expect(response).to be_not_found
    end

    it 'should succeed when owner' do
      stub_current_user(site.owners.first)
      get :show, site_id: site, id: rule
      expect(response).to be_success

      json = JSON.parse(response.body)
      expect(json.keys).to match_array %w(id site_id name priority match conditions description editable)
    end
  end

  describe 'POST :create' do
    before do
      Site.any_instance.stub(generate_script: true)
    end

    it 'should fail when not logged in' do
      post :create, site_id: 1, rule: {}
      expect(response.code).to eq UNAUTHORIZED
    end

    it 'should succeed when not logged in' do
      stub_current_user(site.owners.first)

      expect {
        post :create, site_id: site, rule: {
          name: 'rule name',
          priority: 1
        }
      }.to change(Rule, :count).by(1)

      expect(response).to be_success

      JSON.parse(response.body).tap do |rule|
        expect(rule['site_id']).to eq site.id
        expect(rule['name']).to eq 'rule name'
        expect(rule['priority']).to eq 1
      end
    end

    it 'should be able to create rules with conditions' do
      stub_current_user(site.owners.first)

      rule_name = 'accepting rule and conditions from create'

      post :create, site_id: site, rule: {
        name: rule_name,
        priority: '10',
        match: 'all',
        conditions_attributes: {
          '1' => {
            'segment' => 'CountryCondition', 'operand' => 'is', 'value' => 'USA'
          }
        }
      }

      rule = Rule.last

      rule.name.should == rule_name
      rule.conditions.size.should == 1
    end
  end

  describe 'DELETE :destroy' do
    before do
      Site.any_instance.stub(generate_script: true)
    end

    it 'should fail when not logged in' do
      delete :destroy, site_id: site, id: rule
      expect(response.code).to eq UNAUTHORIZED
    end

    it 'should fail when not site owner' do
      expect(site.owners.first).to eq users(:pro)
      stub_current_user users(:wootie)
      delete :destroy, site_id: site, id: rule
      expect(response).to be_not_found
    end

    it 'should succeed when owner' do
      stub_current_user users(:pro)
      expect {
        delete :destroy, site_id: site, id: rule
      }.to change { Rule.count }.by(-1)
      expect(response).to be_success
    end

    it 'should fail when user only has one rule for their site' do
      site = sites(:horsebike)
      rule = site.rules.first
      stub_current_user(site.owners.first)

      site.rules.count.should == 1

      expect {
        delete :destroy, site_id: site, id: rule
      }.to_not change { Rule.count }

      expect(response.status).to eq(422)
    end
  end

  describe 'PUT :update' do
    before do
      Site.any_instance.stub(generate_script: true)
    end

    it 'should fail when not logged in' do
      put :update, site_id: site, id: rule

      expect(response.code).to eq UNAUTHORIZED
    end

    it 'should fail when not site owner' do
      expect(site.owners.first).to eq users(:pro)

      stub_current_user users(:wootie)
      put :update, site_id: site, id: rule, rule: {}

      expect(response).to be_forbidden
    end

    describe 'succeed as owner' do
      it 'should update a rule with new conditions' do
        stub_current_user(site.owners.first)

        expect {
          put :update, site_id: site, id: rule, rule: {
            name: 'new rule name',
            conditions_attributes: {
              :"0" => condition_hash(:date_between)
            }
          }
        }.to change { Condition.count }.by(1)

        expect(response).to be_success

        JSON.parse(response.body).tap do |rule_obj|
          expect(rule_obj['name']).to eq 'new rule name'

          id = rule_obj['conditions'].first['id']

          expect(rule_obj['conditions']).to eq([{
            'id' => id,
            'rule_id' => rule.id,
            'segment' => 'DateCondition',
            'operand' => 'between',
            'value' => [(Date.current - 1.day).strftime('%Y-%m-%d'), (Date.current + 1.day).strftime('%Y-%m-%d')],
            'custom_segment' => nil,
            'data_type' => nil
          }])
        end
      end

      it 'should properly update the rule when condition attributes are not passed' do
        stub_current_user(site.owners.first)

        put :update, site_id: site, id: rule.id, rule: { name: 'NO CONDITIONS!' }
        rule.reload

        rule.name.should == 'NO CONDITIONS!'
      end

      it 'should add a new rule with url condition' do
        stub_current_user(site.owners.first)

        put :update, site_id: site, id: rule, rule: {
          name: 'new rule name',
          conditions_attributes: {
            :"0" => condition_hash(:url_includes)
          }
        }

        JSON.parse(response.body).tap do |rule_obj|
          id = rule_obj['conditions'].first['id']
          expect(rule_obj['conditions']).to eq([{
            'id' => id,
            'rule_id' => rule.id,
            'segment' => 'UrlCondition',
            'operand' => 'includes',
            'value' => ['/asdf'],
            'custom_segment' => nil,
            'data_type' => nil
          }])
        end
      end

      it 'should two rules at once' do
        stub_current_user(site.owners.first)

        put :update, site_id: site, id: rule, rule: {
          name: 'new rule name',
          conditions_attributes: {
            :"0" => condition_hash(:url_includes),
            :"1" => condition_hash(:date_before)
          }
        }

        JSON.parse(response.body).tap do |rule_obj|
          segments = rule_obj['conditions'].collect { |c| c['segment'] }
          expect(segments).to match_array %w(DateCondition UrlCondition)
        end
      end

      it 'should be able to destroy individual conditions with destroyable' do
        stub_current_user(site.owners.first)

        # add a rule to remove
        rule.conditions << conditions(:url_includes)
        condition = rule.reload.conditions.first

        # remove it
        put :update, site_id: site, id: rule, rule: {
          conditions_attributes: {
            :"0" => { id: condition.id, _destroy: 1 }
          }
        }
        expect { condition.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  private

  def condition_hash(key)
    conditions(key).attributes.tap { |h| h.delete('id') }
  end
end
