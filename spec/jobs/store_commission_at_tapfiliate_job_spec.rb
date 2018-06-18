describe StoreCommissionAtTapfiliateJob do
  let(:job) { described_class }
  let(:gateway) { instance_double TapfiliateGateway }
  let(:bill) { create :bill }

  describe '#perform' do
    let(:perform) { job.new.perform bill }

    it 'calls TapfiliateGateway#store_commission' do
      expect(TapfiliateGateway).to receive(:new).and_return gateway
      expect(gateway).to receive(:store_commission).with bill: bill

      perform
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later(bill)

      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test_lowpriority'
    end
  end
end
