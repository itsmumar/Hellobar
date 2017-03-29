hellobar.defineModule('base.preview', ['hellobar'], function(hellobar) {

  let isActive = false;
  let answerToDisplay = null;

  return {
    isActive: () => isActive,
    setActive () {
      isActive = true;
    },
    setAnswerToDisplay(answer) {
      answerToDisplay = answer;
    },

    getAnswerToDisplay() {
      return answerToDisplay;
    }
  };

});
