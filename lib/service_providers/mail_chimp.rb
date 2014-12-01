class ServiceProviders::MailChimp < ServiceProviders::Email
  include ActionView::Helpers::SanitizeHelper

  def initialize(opts = {})
    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(:provider => 'mailchimp').first
      raise "Site does not have a stored MailChimp identity" unless identity
    end

    @identity = identity
    @client = Gibbon::API.new(identity.credentials['token'], :api_endpoint => identity.extra['metadata']['api_endpoint'])
  end

  def lists
    @lists ||= @client.lists.list(:start => 0, :limit => 100)['data']
  end

  def subscribe(list_id, email, name = nil, double_optin = true)
    opts = {:id => list_id, :email => {:email => email}, :double_optin => double_optin}

    if name
      split = name.split(' ', 2)
      opts[:merge_vars] = {:NAME => name, :FNAME => split[0], :LNAME => split[1]}
    end

    retry_on_timeout do
      begin
        @client.lists.subscribe(opts).tap do |result|
          log result
        end
      rescue Gibbon::MailChimpError => error
        handle_error(error)
      end
    end
  end

  # send subscribers in [{:email => '', :name => ''}, {:email => '', :name => ''}] format
  def batch_subscribe(list_id, subscribers, double_optin = true)
    log "Sending #{subscribers.size} emails to remote service."

    batch = subscribers.map do |subscriber|
      {:EMAIL => {:email => subscriber[:email]}}.tap do |entry|
        if subscriber[:name]
          split = subscriber[:name].split(' ', 2)
          entry[:merge_vars] = {:NAME => subscriber[:name], :FNAME => split[0], :LNAME => split[1], :CREATEDAT => subscriber[:created_at]}
        end
      end
    end

    @client.lists.batch_subscribe({:id => list_id, :batch => batch, :double_optin => double_optin}).tap do |result|
      log handle_result(result)
    end
  end

  def log(message)
    if message.is_a? String
      LogglyLogger.info("#{site.url} - #{message}")
    else
      result = message
      error_count = 0
      if result['errors']
        non_already_subscribed_errors = result['errors'].select { |e| e['code'] != 214 }
        error_count = non_already_subscribed_errors.count
        message = "Added #{result['add_count']} emails, updated #{result['update_count']} emails. " +
                  "#{error_count} errors that weren't just existing subscribers."
      end

      if error_count > 0
        message += "\nA sample of those errors:\n#{non_already_subscribed_errors[0...20].join("\n")}"
        LogglyLogger.error("#{site.url} - #{message}")
      else
        LogglyLogger.info("#{site.url} - #{message}")
      end

      return super message.inspect
    end

    super message
  end

  def handle_error(error)
    case error.code
    when 250
      catch_required_merge_var_error!(error)
    else
      # bubble up to email_synchronizer, which will catch if it is a transient error
      raise error
    end
  end

  def handle_result(result)
    if result['errors']
      result['errors'].each do |error|
        case error['code'].to_i
        when 250
          break catch_required_merge_var_error!(error)
        else
          next
        end
      end
    end

    result
  end

  private

  def catch_required_merge_var_error!(error)
    # pause identity by deleting it
    user = @identity.site.users.first
    if user.temporary_email?
      Rails.logger.warn "Cannot catch required_merge_var error for Contact List #{@identity.contact_list.id} -- user has not yet added their email address."
      return
    end

    Rails.logger.info "required_merge_var_error for Contact List #{@identity.contact_list.id}. Deleting identity and sending email to #{user.email}."

    @identity.delete

    html = <<EOS
<p>Hi there,</p>

<p>It looks like you have required fields in MailChimp, which Hellobar doesn’t support. We've paused your email synchronization to give you a chance to change your MailChimp settings. </p>

<p>To fix this, log into your MailChimp account, select your list, then choose Settings > List fields and Merge tags. Once there, deselect "required" for all fields. Alternately, you may choose a different list to sync with Hellobar.</p>

<p>We understand why you might want to require fields on some forms. In such cases, please consider using a separate MailChimp list for those forms. </p>

<p>Thanks!</p>

<p>Hello Bar</p>
EOS

    MailerGateway.send_email("Custom", user.email,
                              subject: "Your list cannot be synced to Mailchimp",
                              html_body: html,
                              text_body: strip_tags(html))
  end
end
