#= require jquery
#= require jquery_ujs
#= require bootstrap
#= require zeropad.jquery
#= require handlebars
#= require handlebars_helpers
#= require moment
#= require amcharts/amcharts
#= require amcharts/serial
#= require lib/url_params
#= require jstz-1.0.4.min
#= require tablesorter
#= require serialize-json

# Couldn't get 'require_tree .' to ignore the dashboard directory, so I opted to indivdually list the local js assets you needed here

#= require admin_metrics

#= require modal
#= require chart

#= require_tree ./modals
#= require_tree ./charts

#= require site_edit
#= require contact_lists
#= require exit_intent
#= require upgrade_suggest
#= require summary
#= require sites_controller
#= require enforce_restrictions_initializer
#= require flash_message_initializer
#= require install_check
#= require user_edit
#= require referrals
#= require images
#= require header
#= require toastr
#= require clipboard
#= require_self

$ ->

  if (window.location.href.indexOf("pricing-growth") != -1)
    options =
      source: "package-selected"
      package: {"schedule":"monthly","type":"growth","name":"Growth","yearly_amount":"289","monthly_amount":"29","trial":false,"credit_card_id":null,"credit_card_last_digits":null,"payment_valid":true}
      site: window.site
    new PaymentModal(options).open()
  else if (window.location.href.indexOf("pricing-ent") != -1)
    options =
      source: "package-selected"
      package: {"schedule":"monthly","type":"enterprise","name":"Enterprise","yearly_amount":"999","monthly_amount":"99","trial":false,"credit_card_id":null,"credit_card_last_digits":null,"payment_valid":true}
      site: window.site
    new PaymentModal(options).open()
  #Tooltip
  $('[data-toggle="tooltip"]').tooltip()

  # Reveal Blocks
  $('.reveal-wrapper').click (evt) ->
    unless $(@).hasClass('activated')
      $('.reveal-wrapper.activated').removeClass('activated')
      $(@).addClass('activated')

  # Detect User Timezone
  if $('#detect_timezone').length
    $timezone = $('#site_timezone, #user_timezone')
    userTimezone = jstz.determine().name()
    $timezone.val(userTimezone)

  # Confirmation modals
  $('[data-confirm-text]').click (evt) ->
    $t = $(evt.target)

    new ConfirmModal({
      title: $t.data('confirm-title'),
      text: $t.data('confirm-text'),
      url: $t.data('confirm-url'),
      method: $t.data('confirm-method')
    }).open()

    evt.preventDefault()
