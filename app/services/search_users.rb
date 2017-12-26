class SearchUsers
  def initialize(params)
    @page = params[:page]
    @q = params[:q].to_s.strip
  end

  def call
    all || paginate(search)
  end

  private

  attr_reader :q, :page

  def paginate(users)
    Kaminari.paginate_array(users.uniq).page(page).per(24)
  end

  def search
    by_script || by_credit_card || by_site_url_and_username
  end

  def all
    return if q.present?
    User.page(page).per(24).includes(:authentications)
  end

  def by_username
    scope.where('email like ?', "%#{ q }%")
  end

  def by_script
    return unless q =~ /\.js$/

    if (site = Site.by_script(q))
      site.owners.with_deleted
    else
      []
    end
  end

  def by_site_url_and_username
    by_site_url + by_username
  end

  def by_site_url
    domain = NormalizeURI[q]&.domain

    if domain
      user_ids = SiteMembership.with_deleted.joins(:site).where('url LIKE ?', "%#{ domain }%").select(:user_id)
      scope.where(id: user_ids)
    else
      User.none
    end
  end

  def by_credit_card
    return unless q =~ /\d{4}/
    user_ids = CreditCard.with_deleted.where('credit_cards.number like ?', "%-#{ q }%").uniq.select(:user_id)
    scope.where(id: user_ids)
  end

  def scope
    User.with_deleted
  end
end
