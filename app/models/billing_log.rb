require 'git_utils'

class BillingLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :site

  def readonly?
    new_record? ? false : true
  end
end

module BillingAuditTrail
  class BillingAuditor
    def initialize(source)
      @source = source
    end

    def <<(message)
      log = BillingLog.new
      log.message = message
      # Record the current commit and line number and file
      log.source_file = "#{GitUtils.current_commit} @ #{caller.first.split(":in").first.gsub(Rails.root.to_s, "")}"
      # See if we can set the @source_id
      if @source.is_a?(ActiveRecord::Base)
        # Try to set the source id. So if source is a User this would set user_id. If source is a Site this would set site_id
        source_id_setter = :"#{@source.class.model_name.singular}_id="
        if log.respond_to?(source_id_setter)
          log.send(source_id_setter, @source.id)
        end
        # See if the source has any other id attributes we can set
        BillingLog.column_names.each do |name|
          if name =~ /_id$/
            if @source.respond_to?(name)
              log.send(:"#{name}=", @source.send(name))
            end
          end
        end
      end
      # Save it
      log.save!
    end
  end

  def audit
    @auditor ||= BillingAuditor.new(self)
  end
end

# Now add the audit trail to all relevant classes
[User, Site].each do |klass|
  klass.include(BillingAuditTrail)
end
