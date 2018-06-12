describe StoreConversionAtTapfiliateJob do
  let(:job) { described_class }
  let(:gateway) { instance_double TapfiliateGateway }
  let(:user) { create :user, :affiliate }

  describe '#perform' do
    let(:perform) { job.new.perform user }

    it 'calls TapfiliateGateway#store_conversion' do
      expect(TapfiliateGateway).to receive(:new).and_return gateway
      expect(gateway).to receive(:store_conversion).with user: user

      perform
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later(user)
      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test_lowpriority'
    end
  end
end
