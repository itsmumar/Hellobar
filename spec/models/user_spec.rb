require 'spec_helper'

describe User, 'as a valid object' do
  it "cannot have the same email as someone in the wordpress database" do
    Hello::WordpressUser.should_receive(:email_exists?).with("foo@bar.com").and_return(true)

    user = User.create(:email => "foo@bar.com")

    user.errors.messages[:email].should include("has already been taken")
  end

  it 'cannot have the same email as someone in the Rails database' do
    email = 'hoogaboo@gmail.com'
    User.create email: email, password: 'supers3cr37'

    user = User.create email: email

    user.errors.messages[:email].should include('has already been taken')
  end
end

describe User, '.generate_temporary_user' do
  it 'creates a user with a random email and password' do
    expect {
      User.generate_temporary_user
    }.to change(User, :count).by(1)

    User.last.status.should == User::TEMPORARY_STATUS
  end
end
