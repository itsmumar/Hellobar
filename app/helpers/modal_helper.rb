module ModalHelper
  def upgrade_modal_AB_class
    'upgrade-account-modal'
  end

  def allow_exit_intent_modal?
    if current_user.present?
      get_ab_variation("Exit Intent Pop-up Based on Bar Goals 2016-06-08") == "pop_up" ? current_user.can_view_exit_intent_modal? : false
    else
      false
    end
  end
end
