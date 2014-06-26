HelloBar.StepView = Ember.View.extend

  classNameBindings: ['renderedName']


HelloBar.SettingsView  = HelloBar.StepView.extend()
HelloBar.StyleView     = HelloBar.StepView.extend()
HelloBar.ColorsView    = HelloBar.StepView.extend()
HelloBar.TextView      = HelloBar.StepView.extend()
HelloBar.TargetingView = HelloBar.StepView.extend()