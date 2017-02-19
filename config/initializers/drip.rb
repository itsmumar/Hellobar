module Drip
  class Client
    module Tags
      def tags
        get "#{account_id}/tags"
      end
    end
  end

  class Tags < Collection
    def self.collection_name
      "tags"
    end

    def self.resource_name
      "tag"
    end
  end

  class Tag < Resource
    def self.resource_name
      "tag"
    end

    def initialize(raw_data = {})
      @raw_attributes = raw_data.dup.freeze
      @attributes = @raw_attributes
    end
  end

  Collections.module_eval do
    def self.classes
      klasses.map { |klass| klass.pluralize.constantize }
    end
  end

  Resources.module_eval do
    def self.classes
      klasses.map(&:constantize)
    end
  end
end

private
def klasses
  %w(Drip::Account Drip::Subscriber Drip::Tag Drip::Error)
end
