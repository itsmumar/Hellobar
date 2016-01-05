class Referrals::Create < Less::Interaction
  expects :sender
  expects :params
  expects :send_emails

  def run
    @referral = sender.sent_referrals.build(params)
    @referral.state ||= 'sent'

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
    expiration_date = (@referral.created_at + 5.days)
    expiration_date_string = expiration_date.strftime("%B ") + expiration_date.day.ordinalize
    MailerGateway.send_email("Referal Invite Initial", email, {
      referral_sender: sender.email,
      referral_expiration_date: expiration_date_string,
      referral_body: @referral.body,
      referral_link: @referral.url
    })
  end
end