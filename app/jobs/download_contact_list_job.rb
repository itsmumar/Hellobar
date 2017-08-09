class DownloadContactListJob < ApplicationJob
  def perform(current_user, contact_list)
    ContactsMailer.csv_export(current_user, contact_list).deliver_now
  end
end
