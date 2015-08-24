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

  it 'can have the same email as someone in the Rails database if the previous user was deleted' do
    email = 'hoogaboo@gmail.com'
    u = User.create email: email, password: 'supers3cr37'
    u.destroy

    user = User.create email: email

    user.errors.messages[:email].should be_nil
  end

  it 'should require a valid email' do
    u = User.create(email: "test")
    u.errors.messages[:email].should include('is invalid')
  end

  it 'should require a password of 9 characters or more' do
    u = User.create(email: "test@test.com", password: "123")
    u.errors.messages[:password].should include('is too short (minimum is 8 characters)')
  end

  it 'should require password_confirmation to match' do
    u = User.create(email: "test@test.com", password: "12345678", password_confirmation: "sdaf")
    u.errors.messages[:password_confirmation].should include('doesn\'t match Password')
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

describe User, '#active?' do
  let(:user) { User.new }

  it 'returns true when the user is active' do
    user.status = User::ACTIVE_STATUS

    user.should be_active
  end

  it 'returns false when the user is not active' do
    user.status = 'something else'

    user.should_not be_active
  end
end

describe User, '#destroy' do
  fixtures :all
  let(:site_member) { site_memberships(:zombo) }

  before do
    Site.any_instance.stub(:generate_static_assets)
  end

  it 'destroying a user should destroy their sites' do
    user = site_member.user
    site = site_member.site
    user.destroy
    user.destroyed?.should be_true
    site.reload.destroyed?.should be_true
  end

  it "should soft-delete" do
    u = users(:joey)
    u.destroy
    User.only_deleted.should include(u)
  end
end

describe User, "#valid_password?" do
  fixtures :all

  it "is true for valid devise-stored password" do
    user = User.create!(
      email: "newuser@asdf.com",
      password: "asdfasdf"
    )

    user.valid_password?("asdfasdf").should be_true
  end

  it "is true for valid wordpress passwords" do
    user = User.create!(email: "newuser@asdf.com", password: "asdfasdf")
    user.update(encrypted_password: "$P$Brhelf0cSqkZABYCgR08YB8kVp1EFa/")

    user.valid_password?("thisisold").should be_true
  end
end

describe User, ".find_for_google_oauth2" do
  it "creates a new user with the given authentication token" do
    token = {
      "info" => {
        "email" => "test@test.com"
      },
      "uid" => "abc123",
      "provider" => "google_oauth2"
    }

    u = User.find_for_google_oauth2(token)
    u.email.should == "test@test.com"
    u.authentications.count.should == 1
  end

  it "finds a user based on the uid and provider" do
    user = User.create(email: "test@test.com", password: "123devdev", password_confirmation: "123devdev")
    user.authentications.create(provider: "google_oauth2", uid: "abc123")
    token = {
      "info" => {
        "email" => "test@test.com"
      },
      "uid" => "abc123",
      "provider" => "google_oauth2"
    }

    found = User.find_for_google_oauth2(token)
    found.id.should == user.id
  end
end

describe User, "#disconnect_oauth" do
  it "should remove oauth authentications when settings a password" do
    user = User.create(email: "test@test.com", password: "123devdev", password_confirmation: "123devdev")
    user.authentications.create(provider: "google_oauth2", uid: "abc123")
    user = User.find user.id
    user.update_attributes(password: "1234devdev", password_confirmation: "1234devdev")
    user.authentications.count.should == 0
  end
end

describe User, "#name" do
  it "should be nil if first and last are nil" do
    user = User.new(first_name: nil, last_name: nil)
    user.name.should == nil
  end

  it "should first and last name combined" do
    User.new(first_name: "abc", last_name: nil).name.should == "abc"
    User.new(first_name: nil, last_name: "abc").name.should == "abc"
    User.new(first_name: "abc", last_name: "123").name.should == "abc 123"
  end
end
