class ServiceProviders::MailChimp < ServiceProvider
  provider_key :mailchimp
  
  def initialize(opts = {})
    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(:provider => 'mailchimp').first
      raise "Site does not have a stored MailChimp identity" unless identity
    end

    @client = Gibbon::API.new(identity.credentials['token'], :api_endpoint => identity.extra['metadata']['api_endpoint'])
  end

  def lists
    @lists ||= @client.lists.list['data']
  end

  def subscribe(list_id, email, name = nil, double_optin = true)
    opts = {:id => list_id, :email => {:email => email}, :double_optin => double_optin}

    if name
      split = name.split(' ', 2)
      opts[:merge_vars] = {:FNAME => split[0], :LNAME => split[1]}
    end

    @client.lists.subscribe(opts).tap do |result|
      log result
    end
  end

  # send subscribers in [{:email => '', :name => ''}, {:email => '', :name => ''}] format
  def batch_subscribe(list_id, subscribers, double_optin = true)
    subscribers.in_groups_of(1000).collect do |group|
      group.compact!
      log "Sending #{group.size} emails to remote service."

      batch = group.map do |subscriber|
        {:EMAIL => {:email => subscriber[:email]}}.tap do |entry|
          if subscriber[:name]
            split = subscriber[:name].split(' ', 2)
            entry[:merge_vars] = {:FNAME => split[0], :LNAME => split[1], :CREATEDAT => subscriber[:created_at]}
          end
        end
      end

      @client.lists.batch_subscribe({:id => list_id, :batch => batch, :double_optin => double_optin}).tap do |result|
        log result
      end
    end
  end

  def log message
    unless message.is_a? String
      result = message
      non_already_subscribed_errors = result['errors'].select { |e| e['code'] != 214 }
      error_count = non_already_subscribed_errors.count - result['error_count']
      message = "Added #{result['add_count']} emails, updated #{result['update_count']} emails. " + 
                "#{error_count} errors that weren't just existing subscribers."
      message += "\nA sample of those errors:\n#{non_already_subscribed_errors[0...20].join("\n")}" if error_count > 0
    end

    super message
  end
end
