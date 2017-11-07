class BillingMailer < ApplicationMailer
  layout 'user_mailer'

  def could_not_charge(bill)
    @bill = bill
    @site = bill.site
    @subscription = bill.subscription
    @credit_card = bill.credit_card

    mail_to_owners(
      @site,
      subject: default_i18n_subject(card_description: @credit_card.description)
    )
  end

  def no_credit_card(bill)
    @subscription = bill.subscription
    @site = bill.site

    mail_to_owners(@site)
  end

  private

  def mail_to_owners(site, params = {})
    emails = site.owners.pluck(:email)
    mail to: emails.first, cc: emails.from(1), **params
  end
end
