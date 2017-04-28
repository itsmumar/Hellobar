require 'spec_helper'
require 'rake'
load 'lib/tasks/marketing.rake'

describe 'marketing:export_recent_logins_with_plan' do
  include_context 'rake'

  before do
    @user_free_plan = create(:site_membership).user
    create(:subscription, :free, user: @user_free_plan, site: @user_free_plan.sites.first)

    @user_pro_plan = create(:site_membership).user
    create(:subscription, :pro, user: @user_pro_plan, site: @user_pro_plan.sites.first)

    @user_enterprise_plan = create(:site_membership).user
    create(:subscription, :enterprise, user: @user_enterprise_plan, site: @user_enterprise_plan.sites.first)

    files.values.each { |user| user.update_attribute(:current_sign_in_at, Time.zone.now - 10.days) }

    @user_too_old = create(:user, current_sign_in_at: Time.zone.now - 60.days)

    @output = { free: '', pro: '', enterprise: '' }
  end

  let(:files) { { free: @user_free_plan, pro: @user_pro_plan, enterprise: @user_enterprise_plan } }

  it 'should write emails to files' do
    allow(File).to receive(:write) do |*args|
      filename = args[0]
      content = args[1]

      expect(filename).to match(/user_logins_\d*_days/)
      plan_name = filename.match(/user_logins_\d*_days_(.*)_.*/)[1].to_sym
      @output[plan_name] << content
    end

    subject.invoke

    files.each do |plan, user|
      other_emails = (files.values - [user] + [@user_too_old]).collect(&:email)

      expect(@output[plan]).not_to include(*other_emails)
      expect(@output[plan]).to include(user.email)
    end
  end
end

describe 'marketing:export_recent_signups_with_script_install_data' do
  include_context 'rake'

  before do
    @user_with_installed_script = create(:site_membership).user
    @user_with_installed_script.sites.first.update_attribute(:script_installed_at, Time.zone.now - 1.day)

    @user_without_installed_script = create(:site_membership).user

    @user_too_old = create(:user, created_at: Time.zone.now - 60.days)

    @output = { no_script: '', installed_script: '' }
  end

  it 'should write emails to files' do
    allow(File).to receive(:write) do |*args|
      filename = args[0]
      content = args[1]

      expect(filename).to match(/user_signups_\d*_days/)

      if filename.include?('1_or_more_installed_scripts')
        @output[:installed_script] << content
      else
        @output[:no_script] << content
      end
    end

    subject.invoke

    expect(@output[:no_script]).not_to include(@user_with_installed_script.email, @user_too_old.email)
    expect(@output[:no_script]).to include(@user_without_installed_script.email)

    expect(@output[:installed_script]).not_to include(@user_without_installed_script.email, @user_too_old.email)
    expect(@output[:installed_script]).to include(@user_with_installed_script.email)
  end
end
