/* globals siteID, ContactListModal */

import Ember from 'ember';

export default Ember.Route.extend({

  api: Ember.inject.service(),
  validation: Ember.inject.service(),
  bus: Ember.inject.service(),
  applicationSettings: Ember.inject.service(),
  modelLogic: Ember.inject.service(),
  theming: Ember.inject.service(),

  saveCount: 0,

  // TODO check other API calls and move them to api service

  beforeModel() {
    return this.get('applicationSettings').load();
  },

  model() {
    if (localStorage['stashedEditorModel']) {
      const model = JSON.parse(localStorage['stashedEditorModel']);
      localStorage.removeItem('stashedEditorModel');
      return model;
    } else if (window.barID) {
      return this.get('api').siteElement(window.barID);
    } else if (window.elementToCopyID) {
      return this.get('api').siteElement(window.elementToCopyID);
    } else {
      return this.get('api').newSiteElement();
    }
  },

  //-----------  Parse JSON Model  -----------#

  afterModel(resolvedModel) {
    this.get('modelLogic').setModel(resolvedModel);

    if (localStorage['stashedContactList']) {
      const contactList = JSON.parse(localStorage['stashedContactList']);
      localStorage.removeItem('stashedContactList');

      const baseOptions = {
        id: contactList.id,
        siteID,
        editorModel: resolvedModel,
        contactList
      };

      const options = contactList.id ? {
        saveURL: `/sites/${siteID}/contact_lists/${contactList.id}.json`,
        saveMethod: 'PUT',
        success: (data, modal) => {
          resolvedModel.site.contact_lists.forEach((list) => {
            if (list.id === data.id) {
              Ember.set(list, 'name', data.name);
              Ember.set(list, 'provider_name', data.provider_name);
            }
          });
          modal.close();
        }
      } : {
        saveURL: `/sites/${siteID}/contact_lists.json`,
        saveMethod: 'POST',
        success: (data, modal) => {
          let lists = resolvedModel.site.contact_lists.slice(0);
          lists.push({id: data.id, name: data.name, provider_name: data.provider_name});
          this.controller.set('model.site.contact_lists', lists);
          setTimeout((() => {
              this.controller.set('model.contact_list_id', data.id);
            }
          ), 100);
          modal.$modal.remove();
        },
        close: (/* modal */) => {
          this.controller.set('model.contact_list_id', null);
        }
      };
      new ContactListModal($.extend(baseOptions, options)).open();
    }
  }
});
