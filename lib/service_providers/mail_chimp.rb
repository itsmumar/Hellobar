class ServiceProviders::MailChimp < ServiceProviders::Email

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
      @client.lists.subscribe(opts).tap do |result|
        log result
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
      log catch_error(result)
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

  def catch_error(response)
    response.tap do
      if errors = response['errors'].compact
        if error = errors.find {|e| e['code'] == 250 }
          catch_required_merge_var_error!(error)
        end
      end
    end
  end

  private

  def catch_required_merge_var_error!(error)
    # pause identity by deleting it
    user = @identity.site.users.first
    @identity.delete

    body = <<EOS
Hi there,

Unfortunately, we need you to change your MailChimp configuration.

It looks like you're requiring a field. Unfortunately, sometimes users don't
input that field (such as first name or last name), and we can't fill in other fields.

We've paused your email synchronization to give you a chance to get that done.

To fix this, just go to your MailChimp account, select your list, then edit your form.
After that, uncheck "required" for all fields.

We totally understand why you might want to require fields on some forms. In that case,
please consider using a separate MailChimp list for those forms.

Thanks!

Hellobar
EOS

    MailerGateway.send_email("Custom", user.email, body: body)
  end
end
