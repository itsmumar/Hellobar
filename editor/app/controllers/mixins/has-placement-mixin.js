HelloBar.HasPlacement = Ember.Mixin.create({

  selectedPlacement: ( function (key, value) {

    if (arguments.length > 1) {
      this.set('model.placement', value);
      return value;
    } else {
      let current_placement = this.get('model.placement');

      for (let i = 0; i < this.placementOptions.length; i++) {
        let val = this.placementOptions[i];
        if (current_placement === val.value) {
          return current_placement;
        }
      }

      if (this.placementOptions !== null && this.placementOptions.length > 0) {
        current_placement = this.placementOptions[0].value;
        this.set('model.placement', current_placement);
      }

      return current_placement;
    }
  }).property(),

  selectedTrigger: ( function (key, value) {

    if (arguments.length > 1) {
      this.set('model.view_condition', value);
      return value;
    } else {
      let current_trigger = this.get('model.view_condition');

      for (let i = 0; i < this.triggerOptions.length; i++) {
        let val = this.triggerOptions[i];
        if (current_trigger === val.value) {
          return current_trigger;
        }
      }

      if (this.triggerOptions !== null && this.triggerOptions.length > 0) {
        current_trigger = this.triggerOptions[0].value;
        this.set('model.view_condition', current_trigger);
      }

      return current_trigger;
    }
  }).property(),

  actions: {

    popDelayTootlipModal() {
      return new DelayTooltipModal().open();
    }
  }
});
