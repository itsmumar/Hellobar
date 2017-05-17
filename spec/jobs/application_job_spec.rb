describe ApplicationJob do
  describe '#perform' do
    let(:job) { described_class }
    let(:foo_error) { Class.new(StandardError) }

    context 'when error is raised' do
      before { expect_any_instance_of(job).to receive(:perform).and_raise(foo_error) }

      it 'sends exception to Raven' do
        expect(Raven).to receive(:capture_exception).with(instance_of(foo_error))
        job.perform_now
      end
    end
  end
end
