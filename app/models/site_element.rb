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

  validate :contact_list_is_present, if: Proc.new {|se| se.element_subtype == "email"}

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

  def contact_list_is_present
    if contact_list.nil? && (contact_list_id.blank? || contact_list_id == 0)
      errors.add(:contact_list, "can't be blank")
    end
  end
end
