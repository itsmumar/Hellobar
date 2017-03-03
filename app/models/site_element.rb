require 'fog'

class SiteElement < ActiveRecord::Base
  extend ActiveHash::Associations::ActiveRecordExtensions

  TYPES = [Bar, Modal, Slider, Takeover, Custom, ContentUpgrade]

  DEFAULT_EMAIL_THANK_YOU = 'Thank you for signing up!'
  DEFAULT_FREE_EMAIL_THANK_YOU = "#{DEFAULT_EMAIL_THANK_YOU} If you would like this sort of bar on your site..."
  AFTER_EMAIL_ACTION_MAP = {
    0 => :show_default_message,
    1 => :custom_thank_you_text,
    2 => :redirect
  }

  WHITELISTED_TAGS = %w(p strong em u a s sub sup img span ul ol li br hr table tbody tr th td blockquote)
  WHITELISTED_ATTRS = %w(style class href target alt src)

  # valid bar types and their conversion units
  BAR_TYPES = {
    # themes type `generic`
    'call'                            => 'Calls',
    'traffic'                         => 'Clicks',
    'email'                           => 'Emails',
    'announcement'                    => 'Conversions',
    'social/tweet_on_twitter'         => 'Tweets',
    'social/follow_on_twitter'        => 'Follows',
    'social/like_on_facebook'         => 'Likes',
    'social/plus_one_on_google_plus'  => "+1's",
    'social/pin_on_pinterest'         => 'Pins',
    'social/follow_on_pinterest'      => 'Follows',
    'social/share_on_buffer'          => 'Shares',
    'social/share_on_linkedin'        => 'Shares',
    'question'                        => 'Question',

    # themes type `template`
    'traffic_growth'                  => 'Emails'
  }

  TEMPLATE_NAMES = %w(traffic_growth)
  SHORT_SUBTYPES = %w{traffic email call social announcement}

  belongs_to :rule, touch: true
  belongs_to :contact_list
  belongs_to :active_image, class_name: 'ImageUpload'
  belongs_to :theme
  belongs_to :font

  acts_as_paranoid

  validates :element_subtype, presence: true, inclusion: { in: BAR_TYPES.keys }
  validates :rule, association_exists: true
  validates :background_color, :border_color, :button_color, :link_color, :text_color, hex_color: true
  validates :contact_list, association_exists: true, if: :is_email?
  validate :site_is_capable_of_creating_element, unless: :persisted?
  validate :redirect_has_url, if: :is_email?
  validate :has_thank_you_text, if: :is_email?
  validate :subscription_for_custom_targeting

  scope :paused, -> { where("paused = true and type != 'ContentUpgrade'") }
  scope :active, -> { where("paused = false and type != 'ContentUpgrade'") }
  scope :paused_content_upgrades, -> { where("paused = true and type = 'ContentUpgrade'") }
  scope :active_content_upgrades, -> { where("paused = false and type = 'ContentUpgrade'") }
  scope :has_performance, -> { where('element_subtype != ?', 'announcement') }
  scope :bars, -> { where(type: 'Bar') }
  scope :sliders, -> { where(type: 'Slider') }
  scope :custom_elements, -> { where(type: 'Custom') }
  scope :modals_and_takeovers, -> { where(type: %w(Modal Takeover)) }
  scope :email_subtype, -> { where(element_subtype: 'email') }
  scope :social_subtype, -> { where("element_subtype LIKE '%social%'") }
  scope :traffic_subtype, -> { where(element_subtype: 'traffic') }
  scope :call_subtype, -> { where(element_subtype: 'call') }
  scope :announcement_subtype, -> { where(element_subtype: 'announcement') }
  scope :recent, ->(limit) { where('site_elements.created_at > ?', 2.weeks.ago).order('created_at DESC').limit(limit).select { |se| se.is_announcement? || se.has_converted? } }
  scope :matching_content, lambda { |*query|
    matching(:content, *query)
  }

  delegate :site, :site_id, to: :rule, allow_nil: true
  delegate :image_uploads, to: :site
  delegate :url, to: :active_image, allow_nil: true, prefix: :image
  delegate :image_file_name, to: :active_image, allow_nil: true

  serialize :settings, Hash
  serialize :blocks, Array

  after_create :track_creation
  after_save :remove_unreferenced_images
  after_save :update_s3_content

  NOT_CLONEABLE_ATTRIBUTES = [
    :element_subtype,
    :id,
    :created_at,
    :updated_at,
    :deleted_at,
    :paused
  ]

  QUESTION_DEFAULTS = {
    question: 'First time here?',
    answer1: 'Yes',
    answer2: 'No',
    answer1response: 'Welcome! Let’s get started...',
    answer2response: 'Welcome back! Check out our new sale.',
    answer1link_text: 'Take the tour',
    answer2link_text: 'Shop now'
  }

  QUESTION_DEFAULTS.keys.each do |attr_name|
    define_method attr_name do
      if use_question?
        read_attribute(attr_name).presence || QUESTION_DEFAULTS[attr_name]
      end
    end
  end

  def caption=(c_value)
    white_list_sanitizer = Rails::Html::WhiteListSanitizer.new
    c_value = white_list_sanitizer.sanitize(c_value, tags: WHITELISTED_TAGS, attributes: WHITELISTED_ATTRS)
    write_attribute(:caption, c_value)
  end

  def headline=(h_value)
    white_list_sanitizer = Rails::Html::WhiteListSanitizer.new
    h_value = white_list_sanitizer.sanitize(h_value, tags: WHITELISTED_TAGS, attributes: WHITELISTED_ATTRS)
    h_value = 'Hello. Add your message here.' if h_value.blank?
    write_attribute(:headline, h_value)
  end

  def link_text=(lt_value)
    white_list_sanitizer = Rails::Html::WhiteListSanitizer.new
    lt_value = white_list_sanitizer.sanitize(lt_value, tags: WHITELISTED_TAGS, attributes: WHITELISTED_ATTRS)
    write_attribute(:link_text, lt_value)
  end

  def conversion_rate
    total_conversions * 1.0 / total_views
  end

  def related_site_elements
    site.site_elements.where.not(id: id).where(SiteElement.arel_table[:element_subtype].matches("%#{short_subtype}%"))
  end

  def has_activity_message?
    has_converted? || is_announcement?
  end

  def cloneable_attributes
    attributes.reject { |k, _| NOT_CLONEABLE_ATTRIBUTES.include?(k.to_sym) }
  end

  def total_views(opts = {})
    lifetime_totals(opts).try(:views) || 0
  end

  def total_conversions
    lifetime_totals.try(:conversions) || 0
  end

  def conversion_percentage
    total_views == 0 ? 0 : total_conversions.to_f / total_views
  end

  def has_converted?
    total_conversions > 0
  end

  def toggle_paused!
    new_pause_state = !paused?

    update_attribute :paused, new_pause_state
  end

  def short_subtype
    element_subtype[/(\w+)/]
  end

  def track_creation
    analytics_track_site_element_creation!
    onboarding_track_site_element_creation!
  end

  def analytics_track_site_element_creation!
    Analytics.track(
      :site, site_id, 'Created Site Element',
      site_element_id: id,
      type: element_subtype,
      style: type.to_s.downcase
    )
  end

  def onboarding_track_site_element_creation!
    site.owners.each do |user|
      user.onboarding_status_setter.created_element!
    end
  end

  def self.all_templates
    [].tap do |templates|
      TYPES.each do |type|
        BAR_TYPES.keys.each do |subtype|
          if TEMPLATE_NAMES.include?(subtype)
            types = Theme.where(id: subtype.tr('_', '-')).first.element_types
            if types.include?(type.to_s)
              templates << "#{type.name.downcase}_#{subtype}"
            end
          else
            templates << "#{type.name.downcase}_#{subtype}"
          end
        end
      end
    end
  end

  def primary_color
    background_color
  end

  def secondary_color
    button_color
  end

  def display_thank_you_text
    if show_default_email_message?
      default_email_thank_you_text
    else
      read_attribute(:thank_you_text).presence || default_email_thank_you_text
    end
  end

  def default_email_thank_you_text
    if site && site.is_free?
      DEFAULT_FREE_EMAIL_THANK_YOU
    else
      DEFAULT_EMAIL_THANK_YOU
    end
  end

  def after_email_submit_action
    AFTER_EMAIL_ACTION_MAP[settings['after_email_submit_action']]
  end

  def is_announcement?
    element_subtype == 'announcement'
  end

  def show_default_email_message?
    !site.capabilities.custom_thank_you_text? || (after_email_submit_action == :show_default_message)
  end

  def content_upgrade_key
    "#{Site.id_to_script_hash(site.id)}/#{id}.pdf"
  end

  def content_upgrade_download_link
  "https://s3.amazonaws.com/#{Hellobar::Settings[:s3_content_upgrades_bucket]}/#{Site.id_to_script_hash(site.id)}/#{id}.pdf"
  end

  def content_upgrade_script_tag
    '<script id="hb-cu-' + id.to_s + '">window.onload = function() {HB.showContentUpgrade(' + id.to_s + ')};</script>'
  end

  def content_upgrade_wp_shortcode
    '[hellobar_content_upgrade id="' + id.to_s + '"]'
  end

  private

  def update_s3_content
    #don't do this unless you need to
    return if type != 'ContentUpgrade'
    return if content.blank?
    return unless content_changed?

    pdf = WickedPdf.new.pdf_from_string(content)

    # create a connection
    connection = Fog::Storage.new(
      provider: 'AWS',
      aws_access_key_id: Hellobar::Settings[:aws_access_key_id] || 'fake_access_key_id',
      aws_secret_access_key: Hellobar::Settings[:aws_secret_access_key] || 'fake_secret_access_key',
      path_style: true
    )

    directory = connection.directories.get(Hellobar::Settings[:s3_content_upgrades_bucket])

    file = directory.files.create(
      key: content_upgrade_key,
      body: pdf,
      public: true
    )

    file.save
  end

  def remove_unreferenced_images
    # Done through SQL to ensure references are up to date
    image_uploads.joins('LEFT JOIN site_elements ON site_elements.active_image_id = image_uploads.id')\
      .where('site_elements.id IS NULL').destroy_all
  end

  def is_email?
    element_subtype == 'email'
  end

  def lifetime_totals(opts = {})
    return nil if site.nil?
    site.lifetime_totals(opts).try(:[], id.to_s)
  end

  def site_is_capable_of_creating_element
    if site && site.capabilities.at_site_element_limit?
      errors.add(:site, 'is currently at its limit to create site elements')
    end
  end

  def redirect_has_url
    if after_email_submit_action == :redirect
      if !site.capabilities.after_submit_redirect?
        errors.add('settings.redirect_url', 'is a pro feature')
      elsif !settings['redirect_url'].present?
        errors.add('settings.redirect_url', 'cannot be blank')
      end
    end
  end

  def has_thank_you_text
    if after_email_submit_action == :custom_thank_you_text
      if !site.capabilities.custom_thank_you_text?
        errors.add('custom_thank_you_text', 'is a pro feature')
      elsif read_attribute(:thank_you_text).blank?
        errors.add('custom_thank_you_text', 'cannot be blank')
      end
    end
  end

  def has_custom_targeting?
    rule && rule.conditions.any?
  end

  def subscription_for_custom_targeting
    if has_custom_targeting? && !site.capabilities.custom_targeted_bars?
      errors.add(:site, 'subscription does not support custom targeting. Upgrade subscription.')
    end
  end
end
