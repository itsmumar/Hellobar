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
      log.source_file = "#{GitUtils.current_commit} @ #{caller[0..10].collect{|l| l.split(":in").first.gsub(Rails.root.to_s, "")}}"
      # See if we can set the @source_id
      if @source.is_a?(ActiveRecord::Base)
        # See if the source has any other id attributes we can set
        BillingLog.column_names.each do |name|
          if name =~ /_id$/
            # See if it has the id column
            if @source.respond_to?(name)
              log.send(:"#{name}=", @source.send(name))
            end
            # See if this is the source
            class_name = name.gsub(/_id$/,"").classify + (name =~ /s_id$/ ? "s" : "")
            klass = nil
            begin; klass = Kernel.const_get(class_name); rescue; end;
            if klass and @source.is_a?(klass)
              log.send(:"#{name}=", @source.id)
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
