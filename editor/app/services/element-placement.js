import Ember from 'ember';

export default Ember.Service.extend({
  alertPlacement: function () {
    return [
      {value: 'bottom-left', label: 'Bottom left'},
      {value: 'bottom-right', label: 'Bottom right'}
    ];
  }.property(),

  barPlacement: function () {
    return [
      {value: 'bar-top', label: 'Top'},
      {value: 'bar-bottom', label: 'Bottom'}
    ];
  }.property(),

  modalPlacement: function () {
    return [
      {value: 'middle', label: 'Middle'},
      {value: 'top', label: 'Top'}
    ];
  }.property(),

  sliderPlacement: function () {
    return [
      {value: 'bottom-right', label: 'Bottom right'},
      {value: 'top-right', label: 'Top right'},
      {value: 'bottom-left', label: 'Bottom left'},
      {value: 'top-left', label: 'Top left'}
    ];
  }.property(),

  placementOptionsFor (type) {
    const method = `${ type.toLowerCase() }Placement`;
    return this.get(method);
  },

  defaultPlacement (type) {
    const options = this.placementOptionsFor(type);

    if (options && options.length > 0) {
      return options[0].value;
    }
  },

  updatePlacement (component, type) {
    const defaultPlacement = this.defaultPlacement(type);

    component.set('model.placement', defaultPlacement);
  }
});
