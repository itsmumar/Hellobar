require 'rubygems/package'

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
    @client = Gibbon::Request.new({
                api_key: identity.credentials['token'],
                api_endpoint: identity.extra['metadata']['api_endpoint']
              })
  end

  def lists
    @lists ||= @client.lists.retrieve(params: { count: 100 })['lists']
  rescue Gibbon::MailChimpError => error
    handle_error(error)
  end

  def email_exists?(list_id, email)
    member_id = Digest::MD5.hexdigest(email)
    !!@client.lists(list_id).members(member_id).retrieve
  rescue Gibbon::MailChimpError => error
    if error.status_code == 404
      false
    else
      handle_error(error)
    end
  end

  # TODO: Need to improve the performance of this method.
  # MailChimp API v3 doesn't provide any single API to fetch multiple members
  # by their emails
  def subscriber_statuses(list_id, emails)
    result = {}
    batch_response = nil
    repeat_index = 1
    batch_id = nil
    temp_file = 'tarball.tar.gz'
    operations = emails.map do |email|
                   {
                     method: "GET",
                     path: "lists/#{list_id}/members/#{Digest::MD5.hexdigest(email)}"
                   }
                 end

    retry_on_timeout do
      batch_id = @client.batches.create(body: { operations: operations })['id']
    end

    # BAD BAD BAD way of doing this in API v3
    loop do
      sleep(10 * repeat_index)

      puts "Checking batch job status #{repeat_index.ordinalize} time..."
      batch_response = @client.batches(batch_id).retrieve
      break if batch_response['status'] == 'finished'
      repeat_index += 1
    end

    response_body_url = batch_response['response_body_url']
    open(temp_file, 'wb') { |f| f.write(open(response_body_url).read) }
    gz = Zlib::GzipReader.open(File.join(Rails.root, temp_file))
    uncompressed = Gem::Package::TarReader.new(gz)
    responses = uncompressed.map(&:read)
    responses.delete(nil)

    responses.each do |response|
      response = JSON.parse(response)
      next unless response.present?
      response = JSON.parse(response[0]['response'])
      result[response['email_address']] = response['status']
    end

    result
  rescue => e
    Rails.logger.warn("#{site.url} - #{e.message}")
    {}
  end

  def subscribe(list_id, email, name = nil, double_optin = true)
    opts = hashify_options(email, name, double_optin)

    retry_on_timeout do
      begin
        @client.lists(list_id).members.create(body: opts).tap do |result|
          log result
        end
      rescue Gibbon::MailChimpError => error
        handle_error(error)
      end
    end
  end

  # send subscribers in [{:email => '', :name => ''}, {:email => '', :name => ''}] format
  def batch_subscribe(list_id, subscribers, double_optin = true)
    log "Queuing #{subscribers.size} emails to remote service."

    bodies = subscribers.map do |subscriber|
      hashify_options(subscriber[:email], subscriber[:name], double_optin)
    end

    operations = bodies.map do |body|
                   {
                     method: "POST",
                     path: "lists/#{list_id}/members",
                     body: body.to_json
                   }
                 end

    retry_on_timeout do
      # It will enqueue batch operation job to mailchimp and will process
      # in background. We are not bothering about the results as we don't
      # do anything with that except logging it into logs.
      @client.batches.create(body: { operations: operations })
      # repeat_index = 1
      # batch_response = nil
      #
      # loop do
      #   sleep(10 * repeat_index)
      #
      #   puts "Checking batch job status #{repeat_index.ordinalize} time..."
      #   batch_response = @client.batches(batch_id).retrieve
      #   break if batch_response['status'] == 'finished'
      #   repeat_index += 1
      # end
      #
      # batch_response.tap do |result|
      #   log handle_result(result)
      # end
    end
  end

  def log(message)
    if message.is_a? String
      Rails.logger.info("#{site.url} - #{message}")
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
        Rails.logger.error("#{site.url} - #{message}")
      else
        Rails.logger.info("#{site.url} - #{message}")
      end

      return super message.inspect
    end

    super message
  end

  def handle_error(error)
    case error.status_code
    when 250
      catch_required_merge_var_error!(error)
    when 104, 200, 101 #Invalid_ApiKey, Invalid List, Deactivated Account
      identity.destroy_and_notify_user if identity != nil
      raise error
    when 214
      # Email already existed in list, don't do anything
    when -100, -99
      # Email is invalid
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

  def hashify_options(email, name, double_optin)
    opts = { email_address: email }
    opts[:status] = (double_optin ?  "pending" : "subscribed")

    if name.present?
      split = name.split(' ', 2)
      opts[:merge_fields] = {:FNAME => split[0], :LNAME => split[1] || ""}
    end

    opts
  end

  def catch_required_merge_var_error!(error)
    # pause identity by deleting it
    user = @identity.site.users.first
    if user.has_temporary_email?
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
