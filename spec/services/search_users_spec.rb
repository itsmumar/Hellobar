describe SearchUsers do
  let(:users) do
    [
      create(:user, :with_site, :with_credit_card),
      create(:user, :with_site, :with_credit_card),
      create(:user, :with_site, :with_credit_card),
      create(:user, :with_site, :with_credit_card)
    ]
  end

  let(:params) { Hash[q: q, page: 1] }
  let(:service) { SearchUsers.new(params) }

  shared_context 'with deleted users' do
    before do
      users.each(&:destroy)
    end

    context 'with deleted users' do
      it 'includes deleted users' do
        expect(service.call).to match_array(expected)
      end
    end
  end

  shared_examples 'paginator' do
    specify do
      expect(service.call).to respond_to :total_count
      expect(service.call).to respond_to :total_pages
    end
  end

  context 'when :q is blank' do
    let(:q) { '' }
    let(:expected) { users }

    include_context 'with deleted users'
    it_behaves_like 'paginator'

    it 'returns all users' do
      expect(service.call).to match_array(expected)
    end
  end

  context 'when :q matches ".js$"' do
    let(:site) { users.first.sites.with_deleted.first }
    let(:q) { site.script.name }
    let(:expected) { site.owners.with_deleted }

    include_context 'with deleted users'
    it_behaves_like 'paginator'

    it 'returns users with matched script' do
      expect(service.call).to match_array(expected)
    end

    context 'when could not found' do
      let(:q) { 'fake.js' }

      it 'returns empty array' do
        expect(service.call).to be_empty
      end
    end
  end

  context 'when :q matches "\d{4}"' do
    let(:credit_card) { users.last.credit_cards.with_deleted.first }
    let(:q) { credit_card.last_digits }
    let(:expected) { [credit_card.user] }

    include_context 'with deleted users'
    it_behaves_like 'paginator'

    it 'returns users with matched script' do
      expect(service.call).to match_array(expected)
    end
  end

  context 'when site url is given' do
    let(:site) { users.last.sites.with_deleted.first }
    let(:q) { site.url }
    let(:expected) { site.owners.with_deleted }

    include_context 'with deleted users'
    it_behaves_like 'paginator'

    it 'returns users with matched script' do
      expect(service.call).to match_array(expected)
    end
  end

  context 'when part of email is given' do
    let(:user) { users.last }
    let(:q) { user.email.split('@').first }
    let(:expected) { [user] }

    include_context 'with deleted users'
    it_behaves_like 'paginator'

    it 'returns users with matched script' do
      expect(service.call).to match_array(expected)
    end
  end
end
