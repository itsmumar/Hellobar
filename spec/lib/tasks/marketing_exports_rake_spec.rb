require 'spec_helper'
require 'rake'
load 'lib/tasks/marketing.rake'

describe "marketing:export_recent_logins" do
  include_context 'rake'

  let!(:users) {
    [create(:user, current_sign_in_at: Time.zone.now - 1.day),
     create(:user, current_sign_in_at: Time.zone.now - 45.days),
     create(:user, current_sign_in_at: Time.zone.now - 75.days)]
  }

  it 'should write emails to files' do
    File.stub(:write) do |*args, &block|
      filename = args[0]
      content = args[1]

      expect(filename).to match(/user_logins_\d*_days/)
      expect(content).to include(users.first.email)

      user_rows = content.split("\n")[1..-1]
      user_rows.each_with_index do |row, i|
        expect(content).to include(users[i].email)
      end
    end

    subject.invoke
  end
end
