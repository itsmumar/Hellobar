import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  hideLinkText: Ember.computed.match('model.element_subtype', /social|announcement/),

  isABar: Ember.computed.equal('model.type', 'Bar'),

  showQuestionFields: Ember.computed.equal('model.use_question', true),

  setQuestionDefaults: function () {
    if (this.get('model.use_question')) {
      if (!this.get('model.question')) {
        this.set('model.question', this.get('model.question_placeholder'));
      }
      if (!this.get('model.answer1')) {
        this.set('model.answer1', this.get('model.answer1_placeholder'));
      }
      if (!this.get('model.answer2')) {
        this.set('model.answer2', this.get('model.answer2_placeholder'));
      }
      if (!this.get('model.answer1response')) {
        this.set('model.answer1response', this.get('model.answer1response_placeholder'));
      }
      if (!this.get('model.answer2response')) {
        this.set('model.answer2response', this.get('model.answer2response_placeholder'));
      }
      if (!this.get('model.answer1link_text')) {
        this.set('model.answer1link_text', this.get('model.answer1link_text_placeholder'));
      }
      if (!this.get('model.answer2link_text')) {
        return this.set('model.answer2link_text', this.get('model.answer2link_text_placeholder'));
      }
    } else {
      Ember.run.next(() => {
        hellobar('base.preview').setAnswerToDisplay(null);
      });
    }
  }.observes('model.use_question').on('init'),

  actions: {
    showQuestion() {
      hellobar('base.preview').setAnswerToDisplay(null);
      this.set('questionTabSelection', 'TabQuestion');
      // TODO REFACTOR: adopt this
      //this.get('applicationController').renderPreview();
    },

    showAnswer1() {
      hellobar('base.preview').setAnswerToDisplay(1);
      this.set('questionTabSelection', 'TabAnswer1');
      // TODO REFACTOR: adopt this
      //this.get('applicationController').renderPreview();
    },

    showAnswer2() {
      hellobar('base.preview').setAnswerToDisplay(2);
      this.set('questionTabSelection', 'TabAnswer2');
      // TODO REFACTOR: adopt this
      //this.get('applicationController').renderPreview();
    }
  }

});
