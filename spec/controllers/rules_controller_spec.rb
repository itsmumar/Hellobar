describe RulesController do
  before do
    request.env['HTTP_ACCEPT'] = 'application/json'
  end

  let(:user) { create(:user) }
  let(:site) { create(:site, :with_user) }
  let(:owner) { site.owners.first }
  let!(:rule) { create(:rule, site: site) }

  before { create :subscription, :pro, :paid, site: site }

  describe 'GET #show' do
    it 'should fail when not logged in' do
      get :show, site_id: 1, id: rule
      expect(response.code).to eq '401'
    end

    it 'should fail when not owner' do
      stub_current_user user
      get :show, site_id: 1, id: rule
      expect(response).to be_not_found
    end

    it 'should succeed when owner' do
      stub_current_user owner
      get :show, site_id: site, id: rule
      expect(response).to be_successful

      json = JSON.parse(response.body)
      expect(json.keys).to match_array %w[id site_id name match conditions description editable]
    end
  end

  describe 'POST #create' do
    it 'fails when user is not logged in' do
      post :create, site_id: 1, rule: {}
      expect(response.code).to eq '401'
    end

    it 'fails when validation fails' do
      stub_current_user owner

      post :create, site_id: site.id, rule: { name: '' }

      expect(response).not_to be_successful
      expect(response.code).to eq '422'

      body = JSON.parse response.body

      expect(body['rules']).to include "name can't be blank"
    end

    it 'should succeed when not logged in' do
      stub_current_user owner

      expect {
        post :create, site_id: site, rule: { name: 'rule name' }
      }.to change(Rule, :count).by(1)

      expect(response).to be_successful

      JSON.parse(response.body).tap do |rule|
        expect(rule['site_id']).to eq site.id
        expect(rule['name']).to eq 'rule name'
      end
    end

    it 'should be able to create rules with conditions' do
      stub_current_user owner

      rule_name = 'accepting rule and conditions from create'

      post :create, site_id: site, rule: {
        name: rule_name,
        match: 'all',
        conditions_attributes: {
          '0' => {
            'segment' => 'LocationCountryCondition', 'operand' => 'is', 'value' => ['US']
          }
        }
      }

      rule = Rule.last

      expect(rule.name).to eq(rule_name)
      expect(rule.conditions.size).to eq(1)
    end

    it 'regenerates script' do
      stub_current_user owner

      expect { post :create, site_id: site, rule: { name: 'rule name' } }
        .to have_enqueued_job(GenerateStaticScriptJob).with(site)
    end
  end

  describe 'PUT #update' do
    it 'fails when not logged in' do
      put :update, site_id: site, id: rule

      expect(response.code).to eq '401'
    end

    it 'fails when not site owner' do
      stub_current_user user

      put :update, site_id: site, id: rule, rule: {}

      expect(response).to be_forbidden
    end

    it 'fails when validation fails' do
      stub_current_user owner

      params = {
        id: rule.id,
        site_id: site.id,
        rule: {
          name: 'test',
          conditions_attributes: {
            '0' => {
              operand: 'is'
            }
          }
        }
      }

      put :update, params

      expect(response).not_to be_successful
      expect(response.code).to eq '422'

      body = JSON.parse response.body

      expect(body['rules']).to include "segment can't be blank"
      expect(body['rules']).to include 'conditions value is not a valid value'
    end

    describe 'succeed as owner' do
      it 'should update a rule with new conditions' do
        stub_current_user owner

        expect {
          put :update, site_id: site, id: rule, rule: {
            name: 'new rule name',
            conditions_attributes: {
              '0' => condition_hash(:date_between)
            }
          }
        }.to change { Condition.count }.by(1)

        expect(response).to be_successful

        JSON.parse(response.body).tap do |rule_obj|
          expect(rule_obj['name']).to eq 'new rule name'

          id = rule_obj['conditions'].first['id']

          expect(rule_obj['conditions']).to eq([{
            'id' => id,
            'rule_id' => rule.id,
            'segment' => 'DateCondition',
            'operand' => 'between',
            'value' => [(Date.current - 1.day).strftime('%Y-%m-%d'), (Date.current + 1.day).strftime('%Y-%m-%d')]
          }])
        end
      end

      it 'should properly update the rule when condition attributes are not passed' do
        stub_current_user owner

        put :update, site_id: site, id: rule.id, rule: { name: 'NO CONDITIONS!' }
        rule.reload

        expect(rule.name).to eq('NO CONDITIONS!')
      end

      it 'should add a new rule with url condition' do
        stub_current_user owner

        put :update, site_id: site, id: rule, rule: {
          name: 'new rule name',
          conditions_attributes: {
            '0' => condition_hash(:url_includes)
          }
        }

        JSON.parse(response.body).tap do |rule_obj|
          id = rule_obj['conditions'].first['id']
          expect(rule_obj['conditions']).to eq([{
            'id' => id,
            'rule_id' => rule.id,
            'segment' => 'UrlCondition',
            'operand' => 'includes',
            'value' => ['/asdf']
          }])
        end
      end

      it 'should two rules at once' do
        stub_current_user owner

        put :update, site_id: site, id: rule, rule: {
          name: 'new rule name',
          conditions_attributes: {
            '0' => condition_hash(:url_includes),
            '1' => condition_hash(:date_before)
          }
        }

        JSON.parse(response.body).tap do |rule_obj|
          segments = rule_obj['conditions'].collect { |c| c['segment'] }
          expect(segments).to match_array %w[DateCondition UrlCondition]
        end
      end

      it 'should be able to destroy individual conditions with destroyable' do
        stub_current_user owner

        # add a rule to remove
        rule.conditions << create(:condition, :url_includes)
        condition = rule.reload.conditions.first

        # remove it
        put :update, site_id: site, id: rule, rule: {
          conditions_attributes: {
            '0' => { id: condition.id, _destroy: 1 }
          }
        }
        expect { condition.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    it 'regenerates script' do
      stub_current_user owner

      expect { put :update, site_id: site, id: rule.id, rule: { name: 'rule' } }
        .to have_enqueued_job(GenerateStaticScriptJob).with(site)
    end
  end

  describe 'DELETE #destroy' do
    let!(:second_rule) { create(:rule, site: site) }

    it 'should fail when not logged in' do
      delete :destroy, site_id: site, id: rule
      expect(response.code).to eq '401'
    end

    it 'should fail when not site owner' do
      stub_current_user user
      delete :destroy, site_id: site, id: rule
      expect(response).to be_not_found
    end

    it 'fails when validation fails' do
      stub_current_user owner

      expect_any_instance_of(Rule).to receive(:destroy).and_return false

      delete :destroy, site_id: site.id, id: rule.id

      expect(response).not_to be_successful
      expect(response.code).to eq '422'
    end

    it 'should succeed when owner' do
      stub_current_user owner
      expect {
        delete :destroy, site_id: site, id: rule
      }.to change(Rule, :count).by(-1)

      expect(response).to be_successful
    end

    context 'when user only has one rule for their site' do
      let(:second_rule) { nil }

      it 'fails' do
        stub_current_user owner
        expect {
          delete :destroy, site_id: site.id, id: rule
        }.not_to change { Rule.count }

        expect(response.status).to eq(422)
      end
    end

    it 'regenerates script' do
      stub_current_user owner

      expect { delete :destroy, site_id: site.id, id: rule }
        .to have_enqueued_job(GenerateStaticScriptJob).with(site)
    end
  end

  private

  def condition_hash(key)
    attributes_for(:condition, key)
  end
end
