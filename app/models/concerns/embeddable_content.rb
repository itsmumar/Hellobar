module EmbeddableContent
  extend ActiveSupport::Concern

  module ClassMethods
    def content_name=(name)
      instance_variable_set("@content_name", name)
    end

    def content_name
      instance_variable_get("@content_name") || raise('implement me')
    end
  end
end
