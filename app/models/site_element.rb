class SiteElement < ActiveRecord::Base
  TYPES = [Bar, Modal, Slider, Takeover]

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
  validates :background_color, :border_color, :button_color, :link_color, :text_color, hex_color: true

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

  def track_creation
    Analytics.track(:site, self.site.id, "Created Site Element", {site_element_id: self.id, type: self.element_subtype})
  end
  after_create :track_creation

  def self.all_templates
    [].tap do |templates|
      TYPES.each do |type|
        BAR_TYPES.each do |subtype|
          templates << "#{type.name.downcase}_#{subtype}"
        end
      end
    end
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
