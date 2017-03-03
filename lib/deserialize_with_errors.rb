# DeserializeWithErrors - reintroduce raising of errors to invalid JSON
# in TEXT columns that are serialized.

# Rails raises errors when trying to access invalid JSON in VARCHAR columns,
# but not TEXT.

# Usage:

# class MyModel < ActiveRecord::Base
#   include DeserializeWithErrors
#   serialize :data, JSON
# end

module DeserializeWithErrors
  module ClassMethods
    def serialize column, as_type
      
      # Call the parent to install this serializer
      super column, as_type

      # Override the reader method so that we safely access all serialized attributes
      define_method column do |*args|
        case value = super(*args)
        when String
          raise JSON::ParserError
        when NilClass
          {}
        else
          value
        end
      end
    end
  end

  def self.included active_record_class
    active_record_class.extend ClassMethods
  end
end
