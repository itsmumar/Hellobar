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
