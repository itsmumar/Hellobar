describe User do
  describe '#to_s via Rails initializer' do
    it 'includes `id:nil` for non-persisted records' do
      expect(User.new.to_s).to include 'id:nil'
    end

    it 'includes record ID for persisted records' do
      user = create :user

      expect(user.to_s).to include "id:#{ user.id }"
    end
  end

  describe 'validations' do
    it 'cannot have the same email as someone in the Rails database' do
      email = 'hoogaboo@gmail.com'
      User.create email: email, password: 'supers3cr37'

      user = User.create email: email

      expect(user.errors.messages[:email]).to include('has already been taken')
    end

    it 'can have the same email as someone in the Rails database if the previous user was deleted' do
      email = 'hoogaboo@gmail.com'

      user = create :user, email: email
      user.destroy

      new_user = create :user, email: email

      expect(new_user).to be_valid
      expect(new_user).to be_persisted
    end

    it 'should require a valid email' do
      user = User.create(email: 'test')
      expect(user.errors.messages[:email]).to include('is invalid')
    end

    it 'should require a password of 9 characters or more' do
      user = User.create(email: 'test@test.com', password: '123')
      expect(user.errors.messages[:password]).to include('is too short (minimum is 8 characters)')
    end

    it 'should require password_confirmation to match' do
      user = User.create(email: 'test@test.com', password: '12345678', password_confirmation: 'sdaf')
      expect(user.errors.messages[:password_confirmation]).to include('doesn\'t match Password')
    end

    context 'oauth user' do
      let(:user) { create(:authentication).user.reload }

      it 'rejects changes to emails without setting a password' do
        user.update(email: 'changed@email.com')
        expect(user.errors.messages[:email]).to include('cannot be changed without a password.')
      end

      it 'accepts changes to emails when setting a password' do
        user.update(email: 'changed@email.com', password: 'abc123abc', password_confirmation: 'abc123abc')
        expect(user.valid?).to be(true)
      end

      it 'calls disconnect_oauth after saving' do
        expect(user).to receive(:disconnect_oauth)
        user.update(first_name: 'asdfasf')
      end
    end
  end

  describe '#can_view_exit_intent_modal?' do
    let!(:user) { create(:user) }
    let!(:site) { create(:site, :with_rule) }
    let!(:site_membership) { create(:site_membership, site: site, user: user) }
    let!(:site_element) { create(:site_element, rule: site.rules.first) }

    it 'returns false if user has paying subscription' do
      ChangeSubscription.new(site, subscription: 'ProComped', schedule: 'monthly').call
      expect(user.can_view_exit_intent_modal?).to eq(false)
    end

    it 'returns false if user has viewed modal within 30 days' do
      user.update_attributes(exit_intent_modal_last_shown_at: 29.days.ago)
      expect(user.can_view_exit_intent_modal?).to eq(false)
    end

    it 'returns true if user doesnt have paying subscription and hasnt viewed within 30 days' do
      user.update_attributes(exit_intent_modal_last_shown_at: 31.days.ago)
      expect(user.can_view_exit_intent_modal?).to eq(true)
    end
  end

  describe '#most_viewed_site_element' do
    let!(:user) { create(:user) }
    let!(:site) { create(:site, :with_rule) }
    let!(:site_membership) { create(:site_membership, site: site, user: user) }
    let!(:site_element) { create(:site_element, rule: site.rules.first) }
    let(:site_element_w_more_views) { create(:site_element, rule: site.rules.first) }

    before do
      allow(user).to receive(:site_elements).and_return([site_element, site_element_w_more_views])
      allow(site_element).to receive(:total_views).and_return(5)
      allow(site_element_w_more_views).to receive(:total_views).and_return(10)
    end

    it 'returns the site element that has the most views' do
      expect(user.most_viewed_site_element.id).to eq(site_element_w_more_views.id)
    end
  end

  describe '#new?' do
    it 'returns true if the user is logging in for the first time and does not have any bars' do
      user = create(:user)
      # normaly devise would set it
      user.sign_in_count = 1
      user.save
      expect(user.new?).to be_truthy
    end

    it 'returns false if the user logging in for the first time and does have bars' do
      user = create(:user)
      site = user.sites.create(url: generate(:random_uniq_url))
      rule = site.rules.create(name: 'test rule', match: 'all')
      create(:site_element, rule: rule)
      # normaly devise would set it
      user.sign_in_count = 1
      expect(user.new?).to be_falsey
    end

    it 'returns false if the user is not logging in for the first time' do
      user = create(:user)
      # normaly devise would set it
      user.sign_in_count = 2
      user.save
      expect(user.new?).to be_falsey
    end
  end

  describe '#active?' do
    let(:user) { User.new }

    it 'returns true when the user is active' do
      user.status = User::ACTIVE

      expect(user).to be_active
    end

    it 'returns false when the user is not active' do
      user.status = 'something else'

      expect(user).not_to be_active
    end
  end

  describe '#destroy', :freeze do
    let(:site_member) { create(:site_membership) }

    before do
      allow_any_instance_of(GenerateAndStoreStaticScript).to receive(:call)
    end

    it 'marks the record as deleted' do
      user = create(:user)

      user.destroy

      expect(user.deleted_at).to eq Time.current
    end
  end

  describe '#valid_password?' do
    it 'is true for valid devise-stored password' do
      user = User.create!(
        email: 'newuser@asdf.com',
        password: 'asdfasdf'
      )

      expect(user.valid_password?('asdfasdf')).to be_truthy
    end

    it 'is true for valid wordpress passwords' do
      user = User.create!(email: 'newuser@asdf.com', password: 'asdfasdf')
      user.update(encrypted_password: '$P$Brhelf0cSqkZABYCgR08YB8kVp1EFa/')

      expect(user.valid_password?('thisisold')).to be_truthy
    end
  end

  describe '#disconnect_oauth' do
    it 'should remove oauth authentications when settings a password' do
      user = User.create(email: 'test@test.com', password: '123devdev', password_confirmation: '123devdev')
      user.authentications.create(provider: 'google_oauth2', uid: 'abc123')
      user = User.find user.id
      user.update_attributes(password: '1234devdev', password_confirmation: '1234devdev')
      expect(user.authentications.count).to eq(0)
    end
  end

  describe '#name' do
    it 'should be nil if first and last are nil' do
      user = User.new(first_name: nil, last_name: nil)
      expect(user.name).to eq(nil)
    end

    it 'should first and last name combined' do
      expect(User.new(first_name: 'abc', last_name: nil).name).to eq('abc')
      expect(User.new(first_name: nil, last_name: 'abc').name).to eq('abc')
      expect(User.new(first_name: 'abc', last_name: '123').name).to eq('abc 123')
    end
  end

  describe '.search_by_site_url' do
    context 'invalid urls' do
      ['a b c', 'user@email.com', 'site .com'].each do |url|
        it "returns no results for `#{ url }` url" do
          expect(User).to receive(:none)

          User.search_by_site_url url
        end
      end
    end

    context 'valid urls' do
      let(:user) { create :user }

      %w[http://www.google.com https://google.com].each do |url|
        context "when site is added as #{ url }" do
          before do
            user.sites << create(:site, url: url)
          end

          it 'finds user when searching by zone apex' do
            expect(User.search_by_site_url('google.com')).to include user
          end

          it 'finds user when searching by full domain' do
            expect(User.search_by_site_url('www.google.com')).to include user
          end

          it 'finds user when searching by FQDN' do
            expect(User.search_by_site_url('www.google.com.')).to include user
          end
        end
      end
    end
  end

  describe '#valid_password?' do
    let(:user) { create(:user) }
    let(:old_password) { '$P$BU98UgT90LUAD0WPMirJKodNRXW.G5.' }

    it 'works for old hellobar passwords' do
      user.encrypted_password = old_password
      expect(user.valid_password?('test1234')).to be(true)
    end

    it 'catches bcrypt errors when using old hellobar passwords' do
      user.encrypted_password = old_password
      expect(user.valid_password?('wrong password')).to be(false)
    end
  end
end
