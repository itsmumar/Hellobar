module 'editor settings',
  setup: ->
    @route = getModule('route:application')
    ok @route.currentModel
    Ember.run =>
      @route.controller.set('currentUser', {status: 'active'})
    visit 'settings'

test 'it should launch ember immediately', ->
  equal find(".editor-wrapper.ember-view").length, 1, "Ember view should be present"
  equal find("ul.step-links").length, 1, "Side links were not present"
  equal find("ul.action-links .icon-close").length, 1, "Logout link (x) wasn't present"

test 'it should be on settings page by default', ->
  equal find(".step-title").text(), "Settings", "Settings tab was not the launch tab"

test 'it should be able to change goal', ->
  equal find(".step-title").text(), "Settings", "Settings tab was not the launch tab"
  click(find('.change-selection')).andThen =>
    equal find(".step-link-block").length, 3, "Should be 3 goal types"

test 'it should be able to choose an email goal', ->
  click(find('.change-selection')).andThen =>
    clickOn('Collect Email', '.step-link-wrapper').andThen =>
      includes find('.substep').text(),
            "What do you want to collect from visitors?",
            "Substep was not email text"

      # 1. select the element type
      select("Names and email addresses")

      # 2. click next
      clickOn("Next").andThen =>
        equal find(".step-title").text(), "Style", "Should have progressed"

test 'it should be able to choose a social goal', ->
  route = @route

  click(find('.change-selection')).andThen ->
    clickOn('Social', '.step-link-wrapper').andThen =>
      includes find('.substep').text(), "Would you like your visitors to.."

      # 0. Choose a different post type to ensure view switches
      select("+1 on Google+") 
      ok findLabeled("URL to +1")

      # 1. Select the social post type
      select("Tweet on Twitter")

      # 2. fill in tweet message
      fillIn(findLabeled("Message to tweet"), "Yo! This is my tweet").andThen =>

        # verify model was modified
        equal "Yo! This is my tweet",
              route.currentModel.settings.message_to_tweet,
              "Tweet was not changed on model"

        # 3. fill in tweet url
        fillIn(findLabeled("URL to tweet"), "post-that-shit.com").andThen =>

          equal "post-that-shit.com",
                route.currentModel.settings.url_to_tweet,
                "Tweet URL was not changed on model"

          # 4. click next
          clickOn("Next").andThen =>
            equal find(".step-title").text(), "Style", "Should have progressed"

test 'a user can exit the editor when active', ->
  equal find(".icon-close").length, 1, 'renders the editor close button'

test 'it hides the exit editor button if a temporary user', ->
  Ember.run =>
    @route.controller.set('currentUser', {status: 'temporary'})
  equal find(".icon-close").length, 0, 'does not render the editor close button'

test 'it should be able to create a new rules', ->
  $.mockjax
    url: "http://localhost:3000/"
    status: 200
    responseText: {}

  visit('targeting').andThen ->
    equal find('.step-title').text(), "Targeting"

  click('a.edit-rule')

  andThen ->
    $modal = $('.modal-wrapper.show-modal')
    equal $modal.find('h5').text(), 'New Rule', 'we are in the new rule  modal'
    equal $modal.find('input[name="rule[priority]"]').val(), '', 'priority is not set by default'
    equal $modal.find('select[name="rule[match]"]').val(), 'all', 'match is set to all by default'
    equal $modal.find('input[name="rule[name]"]').val(), '', 'name is blank by default'
    equal $modal.find('.condition-block:not(".no-condition-message")').length, 0, 'there should be no conditions'

    $modal.find('input[name="rule[priority]"]').val('100')
    $modal.find('select[name="rule[match]"]').val('any')
    $modal.find('input[name="rule[name]"]').val('super duper')

    # create conditions
    addCondition = $modal.find('.condition-add:first')
    addCondition.click()
    equal $modal.find('.condition-block:not(".no-condition-message")').length, 1, 'builds a new condition'
    equal $modal.find('.country-choice:visible').length, 1, 'makes country condition visible by default'

    equal $modal.find('.device.value:visible').length, 0, 'device is hidden by default'
    $modal.find('.condition-segment').val('DeviceCondition').trigger('change')
    equal $modal.find('.device.value:visible').length, 1, 'shows device once selected'

    $modal.find('.condition-segment').val('UrlCondition').trigger('change')
    equal $modal.find('.device.value:visible').length, 0, 'device is hidden'
    equal $modal.find('.url.value:visible').length, 1, 'url is shown when selected'
