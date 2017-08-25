class DestroyUser
  def initialize(user)
    @user = user
  end

  def call
    downgrade_subscriptions
    destroy_credit_cards
    destroy_own_sites
    user.destroy!
  end

  private

  attr_reader :user

  def downgrade_subscriptions
    subscriptions.each do |subscription|
      ChangeSubscription.new(subscription.site, subscription: 'free').call
    end
  end

  def subscriptions
    Subscription.where(credit_card_id: user.credit_cards.ids)
  end

  def destroy_credit_cards
    user.credit_cards.update_all token: nil
    user.credit_cards.each(&:destroy!)
  end

  def destroy_own_sites
    SiteMembership.where(user_id: user.id, role: 'owner').each do |membership|
      next membership.destroy! unless membership.site

      if membership.site.users.count > 1
        promote_first_user_to_owner(membership)
        membership.destroy!
      else
        DestroySite.new(membership.site).call
      end
    end
  end

  def promote_first_user_to_owner(membership)
    first_site_user = membership.site.site_memberships.where.not(user_id: user.id).first
    first_site_user.update role: 'owner'
  end
end
