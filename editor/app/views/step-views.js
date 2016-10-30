HelloBar.StepView = Ember.View.extend({

  // Generates a commone class name for step views for simplified CSS

  classNameBindings: ['renderedName'],

  // Observe protected features

  updateProFeature: ( function () {
    let isBranded = this.get('controller.model.show_branding');
    let canRemoveBranding = this.get('controller.model.site.capabilities.remove_branding');

    if (!canRemoveBranding && !isBranded) {
      this.set('controller.model.show_branding', true);
      return this.promptUpgrade('show_branding', isBranded, 'remove branding');
    }
  }).observes('controller.model.show_branding'),

  // Upgrade modal promot for protected features

  promptUpgrade(attr, val, message) {
    let view = this;
    return new UpgradeAccountModal({
      site: this.get('controller.model.site'),
      successCallback() {
        view.set('controller.model.site.capabilities', this.site.capabilities); // update site with new capabilities
        return view.set(`controller.model.${attr}`, val);
      },
      upgradeBenefit: message
    }).open();
  }
});


//-----------  Setup Step Views  -----------#

HelloBar.SettingsView = HelloBar.StepView.extend();
HelloBar.StyleView = HelloBar.StepView.extend();
HelloBar.ColorsView = HelloBar.StepView.extend();
HelloBar.TargetingView = HelloBar.StepView.extend();