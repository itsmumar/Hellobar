hellobar.defineModule('base.preview', ['hellobar'], function (hellobar) {

  const configuration = hellobar.createModuleConfiguration({
    previewIsActive: {
      type: 'boolean',
      defaultValue: false
    }
  });

  let answerToDisplay = null;

  return {
    configuration: () => configuration,
    isActive: () => configuration.previewIsActive(),

    setAnswerToDisplay(answer) {
      answerToDisplay = answer;
    },

    getAnswerToDisplay() {
      return answerToDisplay;
    }
  };

});
