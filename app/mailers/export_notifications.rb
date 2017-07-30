class ExportNotifications < ApplicationMailer
  def send_contacts_csv(user, contact_list)
    @contact_list = contact_list
    @total_subscribers = FetchContactListTotals.new(contact_list.site, id: contact_list.id).call
    contacts_zip_file = PrepareZippedContacts.new(contact_list).call
    subject = "#{ contact_list.site.normalized_url }: Your CSV export is ready #{ contact_list.zip_filename }"

    attachments[contact_list.zip_filename] = contacts_zip_file
    mail(to: user.email, subject: subject)
  end
end
