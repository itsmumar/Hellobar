describe SentryJob do
  describe '#perform' do
    let(:job) { described_class }
    let(:event) { { event: :foo_error } }

    context 'when event is tracked' do
      it 'sends exception to Raven' do
        expect(Raven).to receive(:send_event).with(event)

        job.perform_now(event)
      end
    end
  end
end
