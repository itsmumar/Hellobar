require 'spec_helper'

describe UserCampaignController, '#update_exit_intent' do
  let(:user) { create(:user) }
  before { stub_current_user(user) }

  it 'should update user exit intent with current time' do
    post :update_exit_intent, user_id: user.id

    expect(user.reload.exit_intent_modal_last_shown_at)
      .to be_within(2.seconds).of Time.current

    expect(response).to be_success
  end

  it 'should update user upgrade suggest' do
    post :update_upgrade_suggest, user_id: user.id

    expect(user.reload.upgrade_suggest_modal_last_shown_at)
      .to be_within(2.seconds).of Time.current

    expect(response).to be_success
  end
end
