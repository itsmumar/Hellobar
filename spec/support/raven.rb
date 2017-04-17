# Define Raven class for specs with stubbed methods
unless defined? Raven
  class Raven
    class << self
      def user_context *args
      end

      def extra_context *args
      end

      def configure *args
      end

      def capture_exception *args
      end

      def annotate_exception *args
      end
    end
  end
end
