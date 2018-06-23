describe TrackAffiliateConversionJob do
  let(:job) { described_class }
  let(:gateway) { instance_double TapfiliateGateway }
  let(:user) { create :user, :affiliate }

  describe '#perform' do
    let(:perform) { job.new.perform user }

    it 'calls TrackAffiliateConversion service object' do
      expect(TrackAffiliateConversion).to receive_service_call.with user

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
