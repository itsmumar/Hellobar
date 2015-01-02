module 'editor settings',
  setup: ->
    @route = getModule('route:application')
    ok @route.currentModel
    Ember.run =>
      @route.controller.set('currentUser', {status: 'active'})
    visit 'settings'

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
  click(find('.change-selection')).andThen =>
    clickOn('Social', '.step-link-wrapper').andThen =>
      # 0. Choose a different post type to ensure view switches
      clickOn("+1 on Google+")
      ok findLabeled("URL to +1")

      # 1. Select the social post type
      clickOn("Tweet on Twitter")

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

test 'a temp user can exit the editor', ->
  Ember.run =>
    @route.controller.set('currentUser', {status: 'temporary'})
  equal find(".icon-close").length, 1, 'renders the editor close button'
