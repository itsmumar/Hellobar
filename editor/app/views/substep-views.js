HelloBar.StepView = Ember.View.extend({

  // Generates a commone class name for step views for simplified CSS

  classNames: ['substep'],
  classNameBindings: ['renderedClassName'],

  renderedClassName: ( function () {
    return this.get('renderedName').split('.')[1];
  }).property('renderedName')
});


//-----------  Setup Sub-Step Views  -----------#

HelloBar.SettingsEmailsView = HelloBar.StepView.extend();
HelloBar.SettingsSocialView = HelloBar.StepView.extend();
HelloBar.SettingsClickView = HelloBar.StepView.extend();
HelloBar.SettingsCallView = HelloBar.StepView.extend();
HelloBar.SettingsFeedbackView = HelloBar.StepView.extend();
HelloBar.SettingsAnnoucementView = HelloBar.StepView.extend();

HelloBar.StyleBarView = HelloBar.StepView.extend();
HelloBar.StyleModalView = HelloBar.StepView.extend();
HelloBar.StyleSliderView = HelloBar.StepView.extend();
HelloBar.StyleTakeoverView = HelloBar.StepView.extend();

HelloBar.TargetingEveryoneView = HelloBar.StepView.extend();
HelloBar.TargetingMobileView = HelloBar.StepView.extend();
HelloBar.TargetingHomepageView = HelloBar.StepView.extend();
HelloBar.TargetingCustomView = HelloBar.StepView.extend();
HelloBar.TargetingSavedView = HelloBar.StepView.extend();