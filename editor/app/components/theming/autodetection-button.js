import Ember from 'ember';

export default Ember.Component.extend({

  imaging: Ember.inject.service(),

  classNames: ['autodetection-button'],

  imageSrc: function() {
    return this.get('imaging').imagePath('autodetection.png');
  }.property(),

  click() {
    this.sendAction();
  }
});
