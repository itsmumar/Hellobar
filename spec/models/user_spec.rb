require 'spec_helper'

describe User do
  describe "validations" do
    it "cannot have the same email as someone in the wordpress database" do
      expect(Hello::WordpressUser).to receive(:email_exists?).with("foo@bar.com").and_return(true)

      user = User.create(:email => "foo@bar.com")

      expect(user.errors.messages[:email]).to include("has already been taken")
    end

    it 'cannot have the same email as someone in the Rails database' do
      email = 'hoogaboo@gmail.com'
      User.create email: email, password: 'supers3cr37'

      user = User.create email: email

      expect(user.errors.messages[:email]).to include('has already been taken')
    end

    it 'can have the same email as someone in the Rails database if the previous user was deleted' do
      email = 'hoogaboo@gmail.com'
      u = User.create email: email, password: 'supers3cr37'
      u.destroy

      user = User.create email: email

      expect(user.errors.messages[:email]).to be_nil
    end

    it 'should require a valid email' do
      u = User.create(email: "test")
      expect(u.errors.messages[:email]).to include('is invalid')
    end

    it 'should require a password of 9 characters or more' do
      u = User.create(email: "test@test.com", password: "123")
      expect(u.errors.messages[:password]).to include('is too short (minimum is 8 characters)')
    end

    it 'should require password_confirmation to match' do
      u = User.create(email: "test@test.com", password: "12345678", password_confirmation: "sdaf")
      expect(u.errors.messages[:password_confirmation]).to include('doesn\'t match Password')
    end
  end

  describe '.generate_temporary_user' do
    it 'creates a user with a random email and password' do
      expect {
        User.generate_temporary_user
      }.to change(User, :count).by(1)

      expect(User.last.status).to eq(User::TEMPORARY_STATUS)
    end
  end

  describe '#active?' do
    let(:user) { User.new }

    it 'returns true when the user is active' do
      user.status = User::ACTIVE_STATUS

      expect(user).to be_active
    end

    it 'returns false when the user is not active' do
      user.status = 'something else'

      expect(user).not_to be_active
    end
  end

  describe '#destroy' do
    fixtures :all
    let(:site_member) { site_memberships(:zombo) }

    before do
      allow_any_instance_of(Site).to receive(:generate_static_assets)
    end

    it 'destroying a user should destroy their sites' do
      user = site_member.user
      site = site_member.site
      user.destroy
      expect(user.destroyed?).to be_true
      expect(site.reload.destroyed?).to be_true
    end

    it "should soft-delete" do
      u = users(:joey)
      u.destroy
      expect(User.only_deleted).to include(u)
    end
  end

  describe "#valid_password?" do
    fixtures :all

    it "is true for valid devise-stored password" do
      user = User.create!(
        email: "newuser@asdf.com",
        password: "asdfasdf"
      )

      expect(user.valid_password?("asdfasdf")).to be_true
    end

    it "is true for valid wordpress passwords" do
      user = User.create!(email: "newuser@asdf.com", password: "asdfasdf")
      user.update(encrypted_password: "$P$Brhelf0cSqkZABYCgR08YB8kVp1EFa/")

      expect(user.valid_password?("thisisold")).to be_true
    end
  end

  describe ".find_for_google_oauth2" do
    let(:email) { Faker::Internet.email }
    let(:uuid) { SecureRandom.uuid }

    let(:token) do
      {
        "info" => {
          "email" => email
        },
        "uid" => uuid,
        "provider" => "google_oauth2"
      }
    end

    context "when user does not exist" do
      it "creates a new user with correct email" do
        u = User.find_for_google_oauth2(token)

        expect(u.email).to eq(email)
      end

      it "creates a new user with one authentication" do
        u = User.find_for_google_oauth2(token)

        expect(u.authentications.count).to eq(1)
      end

      it "creates a new user with correct provider info" do
        u = User.find_for_google_oauth2(token)

        expect(u.authentications.first.provider).to eq("google_oauth2")
        expect(u.authentications.first.uid).to eq(uuid)
      end

      context "when first and last name provided" do
        let(:first_name) { Faker::Name.first_name }
        let(:last_name) { Faker::Name.last_name }

        before do
          token["info"]["first_name"] = first_name
          token["info"]["last_name"] = last_name
        end

        it "set the first name" do
          u = User.find_for_google_oauth2(token)

          expect(u.first_name).to eq(first_name)
        end

        it "set the last name" do
          u = User.find_for_google_oauth2(token)

          expect(u.last_name).to eq(last_name)
        end
      end
    end

    context "when user exists" do
      it "finds a user based on the uid and provider" do
        user = create_user

        found = User.find_for_google_oauth2(token)

        expect(found.id).to eq(user.id)
      end

      context "when name not set & names passed" do
        let(:first_name) { Faker::Name.first_name }
        let(:last_name) { Faker::Name.last_name }

        before do
          token["info"]["first_name"] = first_name
          token["info"]["last_name"] = last_name
        end

        it "sets the first name" do
          user = create_user
          expect(user.first_name).to be_nil

          found = User.find_for_google_oauth2(token)

          expect(found.reload.first_name).to eq(first_name)
        end

        it "sets the last name" do
          user = create_user
          expect(user.last_name).to be_nil

          found = User.find_for_google_oauth2(token)

          expect(found.reload.last_name).to eq(last_name)

        end
      end

      def create_user
        user = User.create(email: email, password: "123devdev", password_confirmation: "123devdev")
        user.authentications.create(provider: "google_oauth2", uid: uuid)
        user
      end
    end
  end

  describe "#disconnect_oauth" do
    it "should remove oauth authentications when settings a password" do
      user = User.create(email: "test@test.com", password: "123devdev", password_confirmation: "123devdev")
      user.authentications.create(provider: "google_oauth2", uid: "abc123")
      user = User.find user.id
      user.update_attributes(password: "1234devdev", password_confirmation: "1234devdev")
      expect(user.authentications.count).to eq(0)
    end
  end

  describe "#name" do
    it "should be nil if first and last are nil" do
      user = User.new(first_name: nil, last_name: nil)
      expect(user.name).to eq(nil)
    end

    it "should first and last name combined" do
      expect(User.new(first_name: "abc", last_name: nil).name).to eq("abc")
      expect(User.new(first_name: nil, last_name: "abc").name).to eq("abc")
      expect(User.new(first_name: "abc", last_name: "123").name).to eq("abc 123")
    end
  end

  describe "#send_invitation_email" do
    it "should send the token invite email when token has not been redeemed" do
      user = User.new(status: User::TEMPORARY_STATUS, invite_token: "sdaf", invite_token_expire_at: 1.month.from_now)
      expect(user).to receive(:send_invite_token_email)
      user.send_invitation_email(nil)
    end

    it "should send the team invite email if token expired" do
      user = User.new(status: User::TEMPORARY_STATUS, invite_token: "sdaf", invite_token_expire_at: 1.month.ago)
      expect(user).to receive(:send_team_invite_email)
      user.send_invitation_email(nil)
    end

    it "should send the team invite email if user is not temporary" do
      user = User.new(status: User::ACTIVE_STATUS, invite_token: "sdaf", invite_token_expire_at: 1.month.from_now)
      expect(user).to receive(:send_team_invite_email)
      user.send_invitation_email(nil)
    end
  end
end
