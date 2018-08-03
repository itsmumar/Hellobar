import Ember from 'ember';

export default Ember.Service.extend({
  alertPlacement () {
    return [
      {value: 'bottom-right', label: 'Bottom right'},
      {value: 'bottom-left', label: 'Bottom left'}
    ];
  },

  barPlacement () {
    return [
      {value: 'bar-top', label: 'Top'},
      {value: 'bar-bottom', label: 'Bottom'}
    ];
  },

  modalPlacement () {
    return [
      {value: 'middle', label: 'Middle'},
      {value: 'top', label: 'Top'}
    ];
  },

  sliderPlacement () {
    return [
      {value: 'bottom-right', label: 'Bottom right'},
      {value: 'top-right', label: 'Top right'},
      {value: 'bottom-left', label: 'Bottom left'},
      {value: 'top-left', label: 'Top left'}
    ];
  },

  defaultPlacement (type) {
    const method = `${ type.toLowerCase() }Placement`;
    const options = this[method] && this[method]();

    if (options && options.length > 0) {
      return options[0].value;
    }
  },

  updatePlacement (component, type) {
    const defaultPlacement = this.defaultPlacement(type);

    component.set('model.placement', defaultPlacement);
  }
});
