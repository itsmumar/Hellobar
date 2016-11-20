import Ember from 'ember';
import TabViewComponent from './tab-view';

export default TabViewComponent.extend({
  layoutName: (() => 'components/tab-view').property(),

  showQuestion: 'showQuestion',
  showResponse1: 'showResponse1',
  showResponse2: 'showResponse2'
});
