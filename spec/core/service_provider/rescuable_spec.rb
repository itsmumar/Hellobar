describe ServiceProvider::Rescuable do
  class FooException < StandardError; end
  class BarException < StandardError; end

  let(:adapter_class) do
    Class.new(ServiceProvider::Adapters::Base) do
      rescue_from FooException, with: :retry
      rescue_from BarException do |exception|
        self.retry(exception)
      end

      def initialize(exception)
        @exception = exception
      end

      def lists
        raise @exception
      end

      def subscribe(*)
        raise @exception
      end

      def retry(exception)
      end
    end
  end

  context 'when with: :method specified' do
    let(:adapter) { adapter_class.new(FooException) }

    it 'calls rescue handler' do
      expect(adapter).to receive(:retry)
      adapter.subscribe
    end
  end

  context 'when block specified' do
    let(:adapter) { adapter_class.new(BarException) }

    it 'calls rescue handler' do
      expect(adapter).to receive(:retry)
      adapter.subscribe
    end
  end

  context 'when handler is not specified' do
    let(:adapter) { adapter_class.new(StandardError) }

    it 're-raises exception' do
      expect { adapter.lists }.to raise_error(StandardError)
    end
  end
end
