HelloBar.StepView = Ember.View.extend

  # Generates a commone class name for step views for simplified CSS

  classNames: ['substep']
  classNameBindings: ['renderedName']


#-----------  Setup Sub-Step Views  -----------#

HelloBar.SettingsEmailsView      = HelloBar.StepView.extend()
HelloBar.SettingsSocialView      = HelloBar.StepView.extend()
HelloBar.SettingsClickView       = HelloBar.StepView.extend()
HelloBar.SettingsCallView        = HelloBar.StepView.extend()
HelloBar.SettingsFeedbackView    = HelloBar.StepView.extend()
HelloBar.SettingsAnnoucementView = HelloBar.StepView.extend()

HelloBar.StyleBarView            = HelloBar.StepView.extend()
HelloBar.StyleModalView          = HelloBar.StepView.extend()
HelloBar.StyleSliderView         = HelloBar.StepView.extend()
HelloBar.StyleTakeoverView       = HelloBar.StepView.extend()

HelloBar.TargetingLeavingView    = HelloBar.StepView.extend()
HelloBar.TargetingScrollview     = HelloBar.StepView.extend()
HelloBar.TargetingDelayView      = HelloBar.StepView.extend()
