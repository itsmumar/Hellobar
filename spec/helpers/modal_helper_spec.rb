require 'spec_helper'

describe ModalHelper do
  before do
    @user = create(:user)
    allow(helper).to receive(:current_user).and_return(@user)
  end

  describe "allow_exit_intent_modal?" do
    context "user is present and can view exit intent modal" do
      it "returns true if user has 'pop_up' ab test variation" do
        site = @user.sites.create(url: random_uniq_url)
        allow_any_instance_of(ModalHelper).to receive(:get_ab_variation).and_return('pop_up')
        @user.stub(:can_view_exit_intent_modal?).and_return(true)
        expect(helper.allow_exit_intent_modal?(@user)).to eq(true)
      end

      it "returns false if user has 'original' ab test variation" do
        site = @user.sites.create(url: random_uniq_url)
        allow_any_instance_of(ModalHelper).to receive(:get_ab_variation).and_return('original')
        @user.stub(:can_view_exit_intent_modal?).and_return(true)
        expect(helper.allow_exit_intent_modal?(@user)).to eq(false)
      end
    end
  end

  describe "most_viewed_site_element_subtype" do

  end


end
