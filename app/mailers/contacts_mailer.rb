class ContactsMailer < ApplicationMailer
  def csv_export(user, contact_list)
    @contact_list = contact_list

    csv_filename = "#{ contact_list.name.parameterize }.csv"
    zip_filename = "#{ contact_list.name.parameterize }.zip"

    contacts_zip_file = PrepareZippedContacts.new(contact_list, csv_filename).call
    subject = "#{ contact_list.site.host }: Your CSV export is ready #{ zip_filename }"

    attachments[zip_filename] = contacts_zip_file
    mail(to: user.email, subject: subject)
  end
end
