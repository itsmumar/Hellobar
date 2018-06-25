/* globals ContactListModal */

import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  theming: Ember.inject.service(),
  inlineEditing: Ember.inject.service(),
  applicationSettings: Ember.inject.service(),
  palette: Ember.inject.service(),

  currentThemeIsGeneric: Ember.computed.alias('theming.currentThemeIsGeneric'),

  recentColors: Ember.computed.alias('palette.recentColors'),
  siteColors: Ember.computed.alias('palette.colorPalette'),
  focusedColor: Ember.computed.alias('palette.focusedColor'),

  selectedContactList: function () {
    const contactListId = this.get('model.contact_list_id');
    const contactLists = this.get('model.site.contact_lists');
    return _.find(contactLists, (contactList) => contactList.id === contactListId);
  }.property('model.contact_list_id', 'model.site.contact_lists'),

  textFieldBorderWidth: function () {
    return this.get('model.text_field_border_width');
  }.property('model.text_field_border_width'),

  textFieldBorderRadius: function () {
    return this.get('model.text_field_border_radius');
  }.property('model.text_field_border_radius'),

  textFieldBackgroundOpacity: function () {
    return this.get('model.text_field_background_opacity');
  }.property('model.text_field_background_opacity'),

  actions: {

    setContactList(listId) {
      this.set('model.contact_list_id', listId);
    },

    setTextFieldBorderWidth(width) {
      this.set('model.text_field_border_width', parseInt(width));
    },

    setTextFieldBorderRadius(radius) {
      this.set('model.text_field_border_radius', parseInt(radius));
    },

    setTextFieldBackgroundOpacity(opacity) {
      this.set('model.text_field_background_opacity', parseInt(opacity));
    },

    eyeDropperSelected() {
      this.set('focusedColor', null);
      return false;
    },

    openEmailListPopup(listId = 0) {
      const { siteID } = window;

      if (listId) {
        // Edit Existing Contact List
        new ContactListModal({
          id: listId,
          siteID,
          loadURL: `/sites/${siteID}/contact_lists/${listId}.json`,
          saveURL: `/sites/${siteID}/contact_lists/${listId}.json`,
          saveMethod: 'PUT',
          editorModel: this.get('model'),
          canDelete: (listId !== this.get('model.orig_contact_list_id')),

          success: (data, modal) => {
            const iterable = this.get('model.site.contact_lists');
            for (let i = 0; i < iterable.length; i++) {
              let list = iterable[i];
              if (list.id === data.id) {
                Ember.set(list, 'name', data.name);
                Ember.set(list, 'provider_name', data.provider_name);
                break;
              }
            }
            modal.close();
          },

          destroyed: (data, modal) => {
            const lists = this.get('model.site.contact_lists');
            for (let i = 0; i < lists.length; i++) {
              let list = lists[i];
              if (list.id === data.id) {
                lists.removeObject(list);

                if (lists.length > 0) {
                  this.set('model.contact_list_id', lists[0].id);
                }

                break;
              }
            }
            modal.close();
          }
        }).open();

      } else {
        // New Contact List
        new ContactListModal({
          siteID,
          saveURL: `/sites/${siteID}/contact_lists.json`,
          saveMethod: 'POST',
          editorModel: this.get('model'),

          success: (data, modal) => {
            let lists = this.get('model.site.contact_lists').slice(0);
            lists.push({id: data.id, name: data.name, provider_name: data.provider_name});
            this.set('model.site.contact_lists', lists);
            setTimeout(( () => {
                this.set('model.contact_list_id', data.id);
              }
            ), 100);
            modal.$modal.remove();
          },

          close: (/* modal */) => this.set('model.contact_list_id', null)
        }).open();
      }
    }
  }

});
