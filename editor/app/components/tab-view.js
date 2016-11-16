import Ember from 'ember';

export default Ember.Component.extend({
  tagName: 'a',
  classNames: ['nav-pill'],
  classNameBindings: ['isActive:active'],
  attributeBindings: ['onSelection'],
  isActive: (function () {
    return this.get('paneId') === this.get('parentView.activePaneId');
  }).property('paneId', 'parentView.activePaneId'),
  click() {
    this.get('parentView').setActivePane(this.get('paneId'), this.get('name'));
    this.sendAction('doTabSelected', this.get('onSelection'));
  },

  doTabSelected: 'doTabSelected'
});

HelloBar.TabPaneComponent = Ember.Component.extend({
  classNames: ['tab-pane'],
  classNameBindings: ['isActive:active'],
  attributeBindings: ['onSelection'],
  isActive: (function () {
    return this.get('elementId') === this.get('parentView.activePaneId');
  }).property('elementId', 'parentView.activePaneId'),
  didInsertElement() {
    this.get('parentView.panes').pushObject({
      paneId: this.get('elementId'),
      name: this.get('name'),
      action: this.get('onSelection')
    });
    if (this.get(`parentView.model.${this.get('parentView.currentTabNameAttribute')}`) === this.get('name')) {
      this.get('parentView').setActivePane(this.get('elementId'), this.get('name'));
    }
    if (this.get('parentView.activePaneId') === null) {
      this.get('parentView').setActivePane(this.get('elementId'), this.get('name'));
    }
  }
});

HelloBar.TabViewComponent = Ember.Component.extend({
  classNames: ['tab-view'],
  attributeBindings: ['model', 'navigationName'],
  activePaneId: null,
  layoutName: (() => 'components/tab-view').property(),
  didInsertElement() {
    this.set('panes', []);
    this.set('currentTabNameAttribute', `current_${this.get('navigationName')}_tab_name`);
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

HelloBar.QuestionTabsComponent = HelloBar.TabViewComponent.extend({
  layoutName: (() => 'components/tab-view').property(),

  showQuestion: 'showQuestion',
  showResponse1: 'showResponse1',
  showResponse2: 'showResponse2'
});
