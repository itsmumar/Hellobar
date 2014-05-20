class InternalProp < ActiveRecord::Base
end

module HasInternalProps
  def internal_props
    unless @internal_props
      @internal_props = {}
      InternalProp.where(:target_type=>self.class.name.underscore, :target_id=>self.id).order(:timestamp).each do |prop|
        @internal_props[prop.name] = prop.value
      end
    end
    @internal_props
  end
end
