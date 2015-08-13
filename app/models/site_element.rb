class SiteElement < ActiveRecord::Base
  TYPES = [Bar, Modal, Slider, Takeover]

  # valid bar types and their conversion units
  BAR_TYPES = {
    "traffic"                         => "Clicks",
    "email"                           => "Emails",
    "announcement"                    => "Conversions",
    "social/tweet_on_twitter"         => "Tweets",
    "social/follow_on_twitter"        => "Follows",
    "social/like_on_facebook"         => "Likes",
    "social/plus_one_on_google_plus"  => "+1's",
    "social/pin_on_pinterest"         => "Pins",
    "social/follow_on_pinterest"      => "Follows",
    "social/share_on_buffer"          => "Shares",
    "social/share_on_linkedin"        => "Shares"
  }

  SHORT_SUBTYPES = %w{traffic email social announcement}

  belongs_to :rule
  belongs_to :contact_list

  acts_as_paranoid

  validates :element_subtype, presence: true, inclusion: { in: BAR_TYPES.keys }
  validates :rule, association_exists: true
  validates :background_color, :border_color, :button_color, :link_color, :text_color, hex_color: true
  validates :contact_list, association_exists: true, if: :is_email?
  validate :site_is_capable_of_creating_element, unless: :persisted?
  validate :redirect_has_url, if: :is_email?

  scope :paused, -> { where(paused: true) }
  scope :active, -> { where(paused: false) }
  scope :has_performance, -> { where("element_subtype != ?", "announcement") }

  delegate :site, to: :rule, allow_nil: true

  serialize :settings, Hash

  def total_views
    lifetime_totals.try(:views) || 0
  end

  def total_conversions
    lifetime_totals.try(:conversions) || 0
  end

  def conversion_percentage
    total_views == 0 ? 0 : total_conversions.to_f / total_views
  end

  def toggle_paused!
    new_pause_state = !paused?

    update_attribute :paused, new_pause_state
  end

  def short_subtype
    element_subtype[/(\w+)/]
  end

  def track_creation
    Analytics.track(:site, self.site.id, "Created Site Element", {site_element_id: self.id, type: self.element_subtype, style: self.type.to_s.downcase})
  end
  after_create :track_creation

  def self.all_templates
    [].tap do |templates|
      TYPES.each do |type|
        BAR_TYPES.keys.each do |subtype|
          templates << "#{type.name.downcase}_#{subtype}"
        end
      end
    end
  end

  def primary_color
    background_color
  end

  def secondary_color
    background_color
  end

  private

  def is_email?
     element_subtype == "email"
  end

  def lifetime_totals
    return nil if site.nil?
    site.lifetime_totals.try(:[], id.to_s)
  end

  def site_is_capable_of_creating_element
    if site && site.capabilities.at_site_element_limit?
      errors.add(:site, 'is currently at its limit to create site elements')
    end
  end

  def redirect_has_url
    if settings["redirect"] == 1 && !settings["redirect_url"].present?
      errors.add('settings.redirect_url', 'cannot be blank')
    end
  end
end
