class DownloadContactListJob < ApplicationJob
  queue_as { "hb3_#{ Rails.env }" }

  def perform(current_user, contact_list)
    ContactsMailer.csv_export(current_user, contact_list).deliver_now
  end
end
