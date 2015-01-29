HelloBar.StepView = Ember.View.extend

  # Generates a commone class name for step views for simplified CSS

  classNames: ['substep']
  classNameBindings: ['renderedName']

#-----------  Setup Sub-Step Views  -----------#

HelloBar.SettingsEmailsView   = HelloBar.StepView.extend()
HelloBar.SettingsSocialView   = HelloBar.StepView.extend()
HelloBar.SettingsClickView    = HelloBar.StepView.extend()
HelloBar.SettingsFeedbackView = HelloBar.StepView.extend()

HelloBar.StyleBarView         = HelloBar.StepView.extend

  promptUpgrade: ( (attr, val, message) ->
    options =
      site: @get('controller.model.site')
      successCallback: ->
        view.set('controller.model.site.capabilities', this.site.capabilities) # update site with new capabilities
        view.set('controller.model.' + attr, val)
      upgradeBenefit: message

    new UpgradeAccountModal(options).open()
  )

  updateProFeature: ( ->
    canRemoveBranding = @get('controller.model.site.capabilities.remove_branding')
    isBranded = @get('controller.model.show_branding')

    canClose = @get('controller.model.site.capabilities.closable')
    isClosable = @get('controller.model.closable')

    canAnimate = @get('controller.model.site.capabilities.animated')
    isAnimated = @get('controller.model.animated')

    # open upgrade modal if they are trying to unbrand their bar without the capability
    if (!canRemoveBranding && !isBranded)
      @set('controller.model.show_branding', true)
      @promptUpgrade('show_branding', isBranded, "remove branding")
    else if (!canClose && isClosable)
      @set('controller.model.closable', false)
      @promptUpgrade('closable', isClosable, "allow hiding of bars")
    else if (!canAnimate && isAnimated)
      @set('controller.model.animated', false)
      @promptUpgrade('animated', isAnimated, "animate bars")
  ).observes("controller.model.show_branding", "controller.model.closable", "controller.model.animated")

HelloBar.StylePopupView       = HelloBar.StepView.extend()

HelloBar.TargetingLeavingView = HelloBar.StepView.extend()
HelloBar.TargetingScrollview  = HelloBar.StepView.extend()
HelloBar.TargetingDelayView   = HelloBar.StepView.extend()
