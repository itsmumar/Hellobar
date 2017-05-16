import Ember from 'ember';

export default Ember.Mixin.create({

  // TODO REFACTOR -> modelLogic + upgrading service
  promptUpgradeWhenRemovingBranding: function () {
    const isBranded = this.get('model.show_branding');
    const canRemoveBranding = this.get('model.site.capabilities.remove_branding');

    if (!isBranded && !canRemoveBranding) {
      this.set('model.show_branding', true);
      this.promptUpgrade('show_branding', isBranded, 'remove branding');
    }
  }.observes('model.show_branding'),

  // TODO REFACTOR -> modelLogic + upgrading service
  promptUpgradeWhenEnablingHiding: function () {
    const isClosable = this.get('model.closable');
    const canBeClosable = this.get('model.site.capabilities.closable');

    if (isClosable && !canBeClosable) {
      this.set('model.closable', false);
      const elementTypeName = (this.get('model.type') || 'Bar').toLowerCase();
      this.promptUpgrade('closable', isClosable, `allow hiding a ${elementTypeName}`);
    }
  }.observes('model.closable'),

  // TODO REFACTOR -> upgrading service
  promptUpgrade(attr, val, message) {
    const view = this;
    new UpgradeAccountModal({
      site: this.get('model.site'),
      successCallback() {
        view.set('model.site.capabilities', this.site.capabilities); // update site with new capabilities
        return view.set(`model.${attr}`, val);
      },
      upgradeBenefit: message
    }).open();
  }

});
