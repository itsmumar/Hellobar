describe ServiceProvider::Rescuable do
  class FooException < StandardError; end
  class BarException < StandardError; end

  let(:adapter_class) do
    Class.new(ServiceProvider::Adapters::Base) do
      rescue_from FooException, with: :retry
      rescue_from BarException do |exception|
        self.retry(exception)
      end

      def lists
        raise StandardError
      end

      def subscribe(*)
        raise FooException
      end

      def batch_subscribe(*)
        raise BarException
      end

      def retry(exception)
      end
    end
  end
  let(:adapter) { adapter_class.new(double('client')) }

  context 'when with: :method specified' do
    it 'calls rescue handler' do
      expect(adapter).to receive(:retry)
      adapter.subscribe
    end
  end

  context 'when block specified' do
    it 'calls rescue handler' do
      expect(adapter).to receive(:retry)
      adapter.batch_subscribe
    end
  end

  context 'when handler is not specified' do
    it 're-raises exception' do
      expect { adapter.lists }.to raise_error(StandardError)
    end
  end
end
