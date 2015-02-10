class ServiceProviders::MailChimp < ServiceProviders::Email
  include ActionView::Helpers::SanitizeHelper

  def initialize(opts = {})
    super opts

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

  def email_exists?(list_id, email)
    @client.lists.member_info({:id => list_id, :emails => [{:email => email}]})["success_count"] == 1
  end

  def subscriber_statuses(list_id, emails)
    {}.tap do |result|
      emails.each { |e| result[e] = nil }

      emails.each_slice(50) do |email_group|
        email_arr = email_group.map { |x| {email: x} }
        @client.lists.member_info(id: list_id, emails: email_arr)["data"].each do |r|
          result[r["email"]] = r["status"]
        end
      end
    end
  rescue => e
    Rails.logger.warn("#{site.url} - #{e.message}")
    {}
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
      Rails.logger.warn "Cannot catch required_merge_var error for Identity #{@identity.id} -- user has not yet added their email address."
      return
    end

    Rails.logger.info "required_merge_var_error for Contact List #{@identity.id}. Deleting identity and sending email to #{user.email}."

    contact_list_url = Router.new.site_contact_list_url(site, @contact_list, host: Hellobar::Settings[:host])

    html = <<EOS
<p>Hi there,</p>

<p>It looks like you have required fields in MailChimp, which Hellobar doesn’t support. We've paused your email synchronization to give you a chance to change your MailChimp settings. </p>

<p>To fix this, please follow these two steps:</p>

<p>1. Log into your MailChimp account, select your list, then choose Settings > List fields and Merge tags. Once there, deselect "required" for all fields. Alternately, you may choose a different list to sync with Hellobar.</p>
<p>2. Follow this link to resume syncing your Hello Bar contacts to Mailchimp: <a href="#{contact_list_url}">#{contact_list_url}</a></p>

<p>We understand why you might want to require fields on some forms. In such cases, please consider using a separate MailChimp list for those forms. </p>

<p>Thanks!</p>

<p>Hello Bar</p>
EOS

    MailerGateway.send_email("Custom", user.email,
                              subject: "[Action Required] Your list cannot be synced to Mailchimp",
                              html_body: html,
                              text_body: strip_tags(html))

    @identity.delete
  end
end

class Router
  include Rails.application.routes.url_helpers
end
