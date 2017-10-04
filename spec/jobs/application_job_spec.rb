describe ApplicationJob do
  let(:job) do
    Class.new(ApplicationJob) do
      def perform
      end
    end
  end

  describe '#perform' do
    let(:exception) { StandardError.new }

    it 'clears Raven context' do
      expect(Raven::Context).to receive :clear!

      job.perform_now
    end

    context 'when error is raised' do
      before do
        expect_any_instance_of(job).to receive(:perform).and_raise(exception)
      end

      it 'sends exception to Raven and re-raises it' do
        expect(Raven).to receive(:capture_exception)
          .with(exception, extra: instance_of(Hash))

        expect { job.perform_now }.to raise_exception(exception)
      end
    end

    context 'when Aws::S3::Errors::InternalError is raise' do
      let(:job) do
        Class.new(ApplicationJob) do
          def perform
            raise Aws::S3::Errors::InternalError.new('foo', 'bar')
          end
        end
      end

      it 'retries the job' do
        expect_any_instance_of(job).to receive(:retry_job)
        job.perform_now
      end
    end
  end
end
