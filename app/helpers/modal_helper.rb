module ModalHelper
  def upgrade_modal_AB_class
    if get_ab_variation("Upgrade Modal Logos 2016-01-10", current_user) == "logos"
      'upgrade-account-modal with-logos'
    else
      'upgrade-account-modal'
    end
  end
end
