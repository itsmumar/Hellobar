class BillingMailer < ApplicationMailer
  layout 'user_mailer'

  def could_not_charge(bill)
    @bill = bill
    @site = bill.site
    @subscription = bill.subscription
    @credit_card = bill.credit_card

    mail_to_owners(
      @site,
      subject: "We could not charge your #{ @credit_card.description } for your Hello Bar subscription"
    )
  end

  def no_credit_card(bill)
    @subscription = bill.subscription
    @site = bill.site

    mail_to_owners(
      @site,
      subject: 'No credit card on file to renew your Hello Bar subscription'
    )
  end

  private

  def mail_to_owners(site, params = {})
    emails = site.owners.pluck(:email)
    mail to: emails.first, cc: emails.from(1), **params
  end
end
