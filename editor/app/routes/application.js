import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Route.extend({

  api: Ember.inject.service(),
  validation: Ember.inject.service(),

  saveCount: 0,

  // TODO check other API calls and move them to api service

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
        close: modal => {
          this.controller.set('model.contact_list_id', null);
        }
      };
      new ContactListModal($.extend(baseOptions, options)).open();
    }
  },

  //-----------  Actions  -----------#

  // Actions bubble up the routers from most specific to least specific.
  // In order to catch all the actions (because they happen in different
  // routes), the action catch was places in the top-most application route.

  actions: {

    saveSiteElement() {
      const prepareModel = () => {
        _.each(this.currentModel.blocks, (block) => delete block.isDefault);
        if (this.currentModel.phone_number && this.currentModel.phone_country_code) {
          this.currentModel.phone_number = formatE164(this.currentModel.phone_country_code, this.currentModel.phone_number);
        }
      };

      this.get('validation').validate('main', this.currentModel).then(() => {
        // Successful validation
        this.controller.set('validationMessages', null);
        this.controller.toggleProperty('saveSubmitted');
        this.set('saveCount', this.get('saveCount') + 1);
        if (trackEditorFlow) {
          InternalTracking.track_current_person('Editor Flow', {
            step: 'Save Bar',
            goal: this.currentModel.element_subtype,
            style: this.currentModel.type,
            save_attempts: this.get('saveCount')
          });
        }

        const ajaxParams = window.barID ? {
          url: `/sites/${window.siteID}/site_elements/${window.barID}.json`,
          method: 'PUT'
        } : {
          url: `/sites/${window.siteID}/site_elements.json`,
          method: 'POST'
        };

        prepareModel();

        return Ember.$.ajax({
          type: ajaxParams.method,
          url: ajaxParams.url,
          contentType: 'application/json',
          data: JSON.stringify(this.currentModel),

          success: () => {
            if (trackEditorFlow) {
              InternalTracking.track_current_person('Editor Flow', {
                step: 'Completed',
                goal: this.currentModel.element_subtype,
                style: this.currentModel.type,
                save_attempts: this.get('saveCount')
              });
            }
            if (this.controller.get('model.site.num_site_elements') === 0) {
              window.location = `/sites/${window.siteID}`;
            } else {
              window.location = `/sites/${window.siteID}/site_elements`;
            }
          },

          error: data => {
            this.controller.toggleProperty('saveSubmitted');
            this.controller.set('model.errors', data.responseJSON.errors);
            new EditorErrorsModal({errors: data.responseJSON.full_error_messages}).open();
          }
        });
      }, (failures) => {
        // Validation failed
        this.controller.set('validationMessages', failures.map(failure => failure.error));
      });

    }
  }
});
