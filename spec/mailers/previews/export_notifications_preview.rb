# Preview all emails at http://localhost:3000/rails/mailers/export_notifications
class ExportNotificationsPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/export_notifications/contacts_csv
  def send_contacts_csv
    ExportNotifications.send_contacts_csv(User.first, ContactList.last)
  end

end
