import Ember from 'ember';

export default Ember.Component.extend({

  componentRegistry: Ember.inject.service(),

  classNames: ['tab-view', 'js-tab-view'],
  attributeBindings: ['model', 'navigationName'],
  activePaneId: null,
  layoutName: (() => 'components/tab-view').property(),

  didInsertElement() {
    this.set('panes', []);
    this.set('currentTabNameAttribute', `current_${this.get('navigationName')}_tab_name`);
    this.get('componentRegistry').register(this);
  },

  setActivePane(paneId, name) {
    if (this.get('activePaneId') === null) {
      return this.set('activePaneId', paneId);
    } else if (paneId !== this.get('activePaneId')) {
      this.set('activePaneId', paneId);
      return this.set(`model.${this.get('currentTabNameAttribute')}`, name);
    }
  },

  // Listen for paneSelected changes.  When this is changed, grab the pane and
  // and set it as active.
  paneSelectedChange: (function () {
    let pane = this.get('panes')[this.get('model.paneSelectedIndex')];
    return this.setActivePane(pane.paneId, pane.name);
  }).observes('paneSelectionCount'),

  actions: {
    doTabSelected(action) {
      if (action) {
        return this.sendAction(action);
      }
    }
  }
});
