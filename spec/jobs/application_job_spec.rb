describe ApplicationJob do
  let(:job) do
    Class.new(ApplicationJob) do
      def perform
      end
    end
  end

  describe '#perform' do
    let(:foo_error) { Class.new(StandardError) }

    it 'clears Raven context' do
      expect(Raven::Context).to receive(:clear!)
      job.perform_now
    end

    context 'when error is raised' do
      before { expect_any_instance_of(job).to receive(:perform).and_raise(foo_error) }

      it 'sends exception to Raven' do
        expect(Raven).to receive(:capture_exception).with(instance_of(foo_error))
        job.perform_now
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

  describe '.perform_later' do
    let(:foo_error) { Class.new(StandardError) }
    let(:args) { [1, 2, 3] }

    context 'when error is raised' do
      before { expect(job).to receive(:job_or_instantiate).and_raise(foo_error) }

      it 'sends exception to Raven' do
        expect(Raven).to receive(:capture_exception).with(instance_of(foo_error), extra: { arguments: args })
        job.perform_later(*args)
      end
    end
  end
end
