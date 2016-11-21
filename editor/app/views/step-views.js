HelloBar.StepView = Ember.View.extend({

  // Generates a commone class name for step views for simplified CSS

  classNameBindings: ['renderedName'],

  // Observe protected features


});


//-----------  Setup Step Views  -----------#

HelloBar.SettingsView = HelloBar.StepView.extend();
HelloBar.StyleView = HelloBar.StepView.extend();
HelloBar.ColorsView = HelloBar.StepView.extend();
HelloBar.TargetingView = HelloBar.StepView.extend();
