describe TrackAffiliateCommissionJob do
  let(:job) { described_class }
  let(:gateway) { instance_double TapfiliateGateway }
  let(:bill) { create :bill }

  describe '#perform' do
    let(:perform) { job.new.perform bill }

    it 'calls TrackAffiliateCommission service object' do
      expect(TrackAffiliateCommission).to receive_service_call.with bill

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
