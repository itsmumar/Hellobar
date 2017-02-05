import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Route.extend({

  api: Ember.inject.service(),
  validation: Ember.inject.service(),

  saveCount: 0,

  // TODO check other API calls and move them to api service

  model() {
    if (localStorage["stashedEditorModel"]) {
      let model = JSON.parse(localStorage["stashedEditorModel"]);
      localStorage.removeItem("stashedEditorModel");
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
    if (localStorage["stashedContactList"]) {
      let contactList = JSON.parse(localStorage["stashedContactList"]);
      localStorage.removeItem("stashedContactList");

      let baseOptions = {
        id: contactList.id,
        siteID,
        editorModel: resolvedModel,
        contactList
      };

      if (contactList.id) {
        var options = {
          saveURL: `/sites/${siteID}/contact_lists/${contactList.id}.json`,
          saveMethod: "PUT",

          success: (data, modal) => {
            resolvedModel.site.contact_lists.forEach(function (list) {
              if (list.id === data.id) {
                return Ember.set(list, "name", data.name);
              }
            });

            return modal.close();
          }
        };
      } else {
        var options = {
          saveURL: `/sites/${siteID}/contact_lists.json`,
          saveMethod: "POST",

          success: (data, modal) => {
            let lists = resolvedModel.site.contact_lists.slice(0);
            lists.push({id: data.id, name: data.name});
            this.controller.set("model.site.contact_lists", lists);
            setTimeout((() => {
                return this.controller.set("model.contact_list_id", data.id);
              }
            ), 100);
            return modal.$modal.remove();
          },
          close: modal => {
            return this.controller.set("model.contact_list_id", null);
          }
        };
      }

      return new ContactListModal($.extend(baseOptions, options)).open();
    }
  },

  //-----------  Controller Setup  -----------#

  setupController(controller, model) {
    this.controller.set('originalTheme', {
      "theme_id": model.theme_id,
      "button_color": model.button_color,
      "background_color": model.background_color,
      "text_color": model.text_color,
      "link_color": model.link_color
    });

    // Set sub-step forwarding on application load



    let targeting = this.controllerFor('targeting');
    if (model.id) {

    }

    return this._super(controller, model);
  },

  //-----------  Actions  -----------#

  // Actions bubble up the routers from most specific to least specific.
  // In order to catch all the actions (because they happen in different
  // routes), the action catch was places in the top-most application route.

  actions: {

    saveSiteElement() {
      const prepareModel = () => {
        _.each(this.currentModel.blocks, (block) => delete block.isDefault);
      };

      this.get('validation').validate('main', this.currentModel).then(() => {
        // Successful validation
        this.controller.toggleProperty('saveSubmitted');
        // TODO enable button
        this.set('saveCount', this.get('saveCount') + 1);
        if (trackEditorFlow) {
          InternalTracking.track_current_person('Editor Flow', {
            step: 'Save Bar',
            goal: this.currentModel.element_subtype,
            style: this.currentModel.type,
            save_attempts: this.get('saveCount')
          });
        }

        if (window.barID) {
          var url = `/sites/${window.siteID}/site_elements/${window.barID}.json`;
          var method = 'PUT';
        } else {
          var url = `/sites/${window.siteID}/site_elements.json`;
          var method = 'POST';
        }

        prepareModel();

        return Ember.$.ajax({
          type: method,
          url,
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
            this.controller.set("model.errors", data.responseJSON.errors);
            new EditorErrorsModal({errors: data.responseJSON.full_error_messages}).open();
          }
        });
      }, () => {
        // Validation failed
        // TODO disable button
      });

    }
  }
});
