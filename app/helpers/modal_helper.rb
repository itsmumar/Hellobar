module ModalHelper
  def upgrade_modal_AB_class
    'upgrade-account-modal'
  end

  def allow_exit_intent_modal?(user)
    return false unless user.present?
    get_ab_variation("Exit Intent Pop-up Based on Bar Goals 2016-06-08") == "pop_up" ? current_user.can_view_exit_intent_modal? : false
  end

  def most_viewed_site_element_subtype(user)
    subtype = user.most_viewed_site_element.element_subtype
    subtype = "social" if subtype && subtype.include?("social")
    subtype
  end
end
