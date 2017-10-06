describe ApplicationJob do
  let(:job) do
    Class.new(ApplicationJob) do
      def perform
      end
    end
  end

  describe '#perform' do
    it 'clears Raven context after #perform' do
      expect(Raven::Context).to receive :clear!

      job.perform_now
    end

    context 'when ActiveJob::DeserializationError is raised' do
      let(:exception) { ActiveJob::DeserializationError.new OpenStruct.new }

      before do
        expect_any_instance_of(job).to receive(:perform).and_raise(exception)
      end

      it 'captures the exception and logs it' do
        expect(Shoryuken.logger).to receive(:error).twice

        expect { job.perform_now }.not_to raise_exception
      end
    end

    context 'when StandardError is raised' do
      let(:exception) { StandardError.new }

      before do
        expect_any_instance_of(job).to receive(:perform).and_raise(exception)
      end

      it 'sends exception to Raven and re-raises it' do
        expect(Raven).to receive(:capture_exception)
          .with(exception, extra: instance_of(Hash))

        expect { job.perform_now }.to raise_exception(exception)
      end
    end

    context 'when Aws::S3::Errors::InternalError is raised' do
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
