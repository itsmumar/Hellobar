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
    return new Ember.RSVP.Promise((resolve, reject) => {
      const loadModel = () => {
        this.loadModel().then(resolve, reject);
      };
      this.get('applicationSettings').load().then(loadModel, reject);
    });
  },

  loadModel() {
    return new Ember.RSVP.Promise((resolve, reject) => {
      if (localStorage['stashedEditorModel']) {
        const model = JSON.parse(localStorage['stashedEditorModel']);
        localStorage.removeItem('stashedEditorModel');
        resolve(model);
      } else if (window.barID) {
        this.get('api').siteElement(window.barID).then(resolve, reject);
      } else if (window.elementToCopyID) {
        this.get('api').siteElement(window.elementToCopyID).then(resolve, reject);
      } else {
        this.get('api').newSiteElement().then(resolve, reject);
      }
    }).then(model => {
      this.get('modelLogic').setModel(model);
    });
  },

  model () {
    return this.get('modelLogic.model');
  },

  setupController (controller, model) {
    controller.set('model', model);
  },

  //-----------  Parse JSON Model  -----------#

  afterModel(resolvedModel) {
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
