class SiteElement < ActiveRecord::Base
  BAR_TYPES = %w{
    traffic
    email
    social/tweet_on_twitter
    social/follow_on_twitter
    social/like_on_facebook
    social/share_on_linkedin
    social/plus_one_on_google_plus
    social/pin_on_pinterest
    social/follow_on_pinterest
    social/share_on_buffer
  }
  SHORT_SUBTYPES = %w{traffic email social}

  DISPLAY_WHEN_OPTIONS = %w{
    immediately
    after_leaving
    after_scroll
    after_delay
  }

  belongs_to :rule
  belongs_to :contact_list

  validates :element_subtype, presence: true, inclusion: { in: BAR_TYPES }
  validates :rule, association_exists: true
  validates :display_when, inclusion: { in: DISPLAY_WHEN_OPTIONS }

  validate :site_is_capable_of_creating_element, unless: :persisted?

  scope :paused, -> { where(paused: true) }
  scope :active, -> { where(paused: false) }

  delegate :site, to: :rule, allow_nil: true

  serialize :settings, Hash

  def total_views
    total_views_and_conversions[0]
  end

  def total_conversions
    total_views_and_conversions[1]
  end

  def conversion_percentage
    total_views == 0 ? 0 : total_conversions * 1.0 / total_views
  end

  def toggle_paused!
    new_pause_state = !paused?

    update_attribute :paused, new_pause_state
  end

  def short_subtype
    element_subtype[/(\w+)/]
  end

  private

  def total_views_and_conversions
    return [0, 0] unless site

    data = site.lifetime_totals

    if data.nil? || data[id.to_s].nil?
      [0, 0]
    else
      data[id.to_s].last
    end
  end

  def site_is_capable_of_creating_element
    if site && site.capabilities.at_site_element_limit?
      errors.add(:site, 'is currently at its limit to create site elements')
    end
  end
end
