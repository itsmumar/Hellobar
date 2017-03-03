class Referrals::Create < Less::Interaction
  expects :sender
  expects :params
  expects :send_emails

  def run
    @referral = sender.sent_referrals.build(params)
    @referral.set_site_if_only_one

    if @referral.save && send_emails
      send_initial_email
    end

    @referral
  end

  private

  def email
    params[:email]
  end

  def send_initial_email
    MailerGateway.send_email('Referral Invite Initial', email, {
      referral_sender: sender.name,
      referral_expiration_date: @referral.expiration_date_string,
      referral_body: @referral.body,
      referral_link: @referral.url
    })
  end
end
