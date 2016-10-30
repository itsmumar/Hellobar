HelloBar.ScrollSelect = Ember.View.extend({

  tagName: 'label',
  classNameBindings: ['isSelected'],

  notSelected: Ember.computed.not('isSelected'),
  isSelected: (function () {
    return (this.get('controller.model.settings.display_when_scroll_type') === this.get('type'));
  }).property('controller.model.settings.display_when_scroll_type'),

  click() {
    return this.set('controller.model.settings.display_when_scroll_type', this.type);
  }
});
