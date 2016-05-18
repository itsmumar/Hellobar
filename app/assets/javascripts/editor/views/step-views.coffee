HelloBar.StepView = Ember.View.extend

  # Generates a commone class name for step views for simplified CSS

  classNameBindings: ['renderedName']

  # Observe protected features

  updateProFeature: ( ->
    isBranded = @get('controller.model.show_branding')
    canRemoveBranding = @get('controller.model.site.capabilities.remove_branding')

    if (!canRemoveBranding && !isBranded)
      @set('controller.model.show_branding', true)
      @promptUpgrade('show_branding', isBranded, 'remove branding')
  ).observes('controller.model.show_branding')

  # Upgrade modal promot for protected features

  promptUpgrade: (attr, val, message) ->
    view = @
    new UpgradeAccountModal(
      site: @get('controller.model.site')
      successCallback: ->
        view.set('controller.model.site.capabilities', @site.capabilities) # update site with new capabilities
        view.set('controller.model.' + attr, val)
      upgradeBenefit: message
    ).open()


#-----------  Setup Step Views  -----------#

HelloBar.SettingsView  = HelloBar.StepView.extend()
HelloBar.StyleView     = HelloBar.StepView.extend()
HelloBar.ColorsView    = HelloBar.StepView.extend()
HelloBar.TargetingView = HelloBar.StepView.extend()