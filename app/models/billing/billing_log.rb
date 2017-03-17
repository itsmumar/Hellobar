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
    attr_accessor :debug
    def initialize(source, debug = false)
      @source = source
      @debug = debug
    end

    def <<(message)
      log = BillingLog.new
      log.message = message
      # Record the current commit and line number and file
      log.source_file = "#{ GitUtils.current_commit } @ #{ caller[0..20].collect { |l| l.split(':in').first.gsub(Rails.root.to_s, '') }.join("\n") }"
      # See if we can set the @source_id
      if @source.is_a?(ActiveRecord::Base)
        # See if the source has any other id attributes we can set
        BillingLog.column_names.each do |name|
          next unless name =~ /_id$/
          # See if it has the id column
          log.send(:"#{name}=", @source.send(name)) if @source.respond_to?(name)
          # See if this is the source
          class_name = name.gsub(/_id$/, '').classify + (name =~ /s_id$/ ? 's' : '')
          klass = nil
          begin
            klass = Kernel.const_get(class_name)
          rescue => e
            Raven.capture_exception(e)
          end
          log.send(:"#{name}=", @source.id) if klass && @source.is_a?(klass)
        end
      end
      # Save it
      if @debug
        Rails.logger.debug '=' * 80
        Rails.logger.debug log.source_file
        Rails.logger.debug '-' * 80
        Rails.logger.debug log.message
        Rails.logger.debug '-' * 80
        log.attribute_names.sort.each do |n|
          unless [:message, :source_file, :created_at, :id].include?(n.to_sym)
            Rails.logger.debug "\t#{ n } => #{ log.send(n) }"
          end
        end
        Rails.logger.debug '=' * 80
        Rails.logger.debug log.inspect
      end
      log.save!
    end
  end

  def audit(debug = false)
    @auditor ||= BillingAuditor.new(self, debug)
    @auditor.debug = debug
    @auditor
  end
end
