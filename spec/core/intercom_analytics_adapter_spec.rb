describe IntercomAnalyticsAdapter do
  let!(:user) { create :user }
  let(:intercom_gateway) { instance_double(IntercomGateway) }
  let(:params) { Hash[foo: 'bar'] }
  let(:adapter) { IntercomAnalyticsAdapter.new }

  before do
    allow(IntercomGateway)
      .to receive(:new)
      .and_return intercom_gateway
  end

  describe '#track' do
    it 'sends event with IntercomGateway', :freeze do
      expect(intercom_gateway).to receive(:track).with(
        event_name: 'event',
        user_id: user.id,
        created_at: Time.current.to_i,
        metadata: params
      )

      adapter.track(
        event: 'event',
        user: user,
        params: params
      )
    end
  end

  describe '#tag_users' do
    let(:users) { build_list :user, 2 }

    it 'calls IntercomGateway#tag_users' do
      expect(intercom_gateway).to receive(:tag_users).with(
        'Tag',
        users
      )

      adapter.tag_users 'Tag', users
    end

    context 'when a user does not exist at Intercom' do
      let(:exception) do
        Intercom::ResourceNotFound.new(IntercomAnalyticsAdapter::USER_NOT_FOUND)
      end

      it 'calls IntercomGateway#tag_users' do
        expect(intercom_gateway)
          .to receive(:tag_users)
          .with('Tag', users)
          .and_raise(exception)
          .once

        users.each do |user|
          expect(intercom_gateway).to receive(:create_user).with(user)
        end

        expect(intercom_gateway)
          .to receive(:tag_users)
          .with('Tag', users)
          .once

        adapter.tag_users 'Tag', users
      end
    end
  end

  describe '#untag_users' do
    let(:users) { build_list :user, 2 }

    it 'calls IntercomGateway#untag_users' do
      expect(intercom_gateway).to receive(:untag_users).with(
        'Tag',
        users
      )

      adapter.untag_users 'Tag', users
    end

    context 'when a user does not exist at Intercom' do
      let(:exception) do
        Intercom::ResourceNotFound.new(IntercomAnalyticsAdapter::USER_NOT_FOUND)
      end

      it 'calls IntercomGateway#tag_users' do
        expect(intercom_gateway)
          .to receive(:untag_users)
          .with('Tag', users)
          .and_raise(exception)
          .once

        users.each do |user|
          expect(intercom_gateway).to receive(:create_user).with(user)
        end

        expect(intercom_gateway)
          .to receive(:untag_users)
          .with('Tag', users)
          .once

        adapter.untag_users 'Tag', users
      end
    end
  end

  describe '#update_user' do
    let(:user) { create :user }
    let(:params) { Hash[foo: :bar] }

    it 'calls IntercomGateway#update_user' do
      expect(intercom_gateway)
        .to receive(:update_user)
        .with(user.id, params)

      adapter.update_user user: user, params: params
    end
  end
end
