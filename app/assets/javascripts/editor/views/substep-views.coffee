HelloBar.StepView = Ember.View.extend

  classNames: ['substep']
  classNameBindings: ['renderedName']
    

HelloBar.SettingsEmailsView   = HelloBar.StepView.extend()
HelloBar.SettingsSocialView   = HelloBar.StepView.extend()
HelloBar.SettingsClickView    = HelloBar.StepView.extend()
HelloBar.SettingsFeedbackView = HelloBar.StepView.extend()

HelloBar.StyleBarView         = HelloBar.StepView.extend()
HelloBar.StylePopupView       = HelloBar.StepView.extend()
