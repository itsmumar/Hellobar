class SearchUsers
  PER_PAGE = 24

  def initialize(params)
    @page = params[:page]
    @q = params[:q].to_s.strip
  end

  def call
    paginate(search)
  end

  private

  attr_reader :q, :page

  def paginate(users)
    users.page(page).per(PER_PAGE)
  end

  def search
    users = by_script
    users = by_credit_card if users.blank?
    users = by_site_url_and_username if users.blank?
    users = all if users.blank?
    users
  end

  def all
    User.all.includes(:authentications)
  end

  def by_script
    return unless q =~ /\.js$/

    target_hash = q.gsub(/^.*\//, '').gsub(/\.js$/, '')

    site = Site.with_deleted.find_by(
      'SHA1(CONCAT(:prefix, id, :suffix)) = :hash',
      **StaticScript.hash_content, hash: target_hash
    )
    site&.owners&.with_deleted
  end

  def by_site_url_and_username
    return if q.blank?
    Kaminari.paginate_array((by_site_url + by_username).uniq)
  end

  def by_username
    scope.where('email like ?', "%#{ q }%")
  end

  def by_site_url
    domain = NormalizeURI[q]&.domain

    if domain
      user_ids =
        SiteMembership
        .with_deleted.joins('INNER JOIN sites ON sites.id = site_memberships.site_id')
        .where('url LIKE ?', "%#{ domain }%").select(:user_id)

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
