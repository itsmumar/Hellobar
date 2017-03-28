hellobar.defineModule('elements.questions', [], function () {

  // TODO -> elements.questions ????
  // Replaces the site element with the question variation.
  // Sets the displayResponse callback to show the original element
  function questionifySiteElement(siteElement) {
    if (!siteElement.use_question || !siteElement.dataCopy)
      return siteElement;

    // Create a copy of the siteElement
    var originalSiteElement = siteElement;
    siteElement = siteElement.dataCopy;

    siteElement.questionified = true;

    // Set the template and headline
    // Remove the image from the question
    siteElement.template_name = siteElement.template_name.split('_')[0] + '_question';
    siteElement.headline = siteElement.question;
    siteElement.caption = null;
    siteElement.use_question = false;
    siteElement.image_url = null;

    // Create the new question site element
    siteElement = HB.createSiteElement(siteElement);

    // Set the callback.  When this is called, it sets the values on the original element
    // and displays it.
    siteElement.displayResponse = function (choice) {
      // If showResponse has not been set (ie, not forcing an answer to display)
      // trigger the answerSelected event
      if (!HB.showResponse) {
        HB.trigger('answerSelected', choice); // Old-style trigger
        HB.trigger('answered', siteElement, choice); // New trigger
      }

      if (choice === 1) {
        originalSiteElement.headline = siteElement.answer1response;
        originalSiteElement.caption = siteElement.answer1caption;
        originalSiteElement.link_text = siteElement.answer1link_text;
      } else {
        originalSiteElement.headline = siteElement.answer2response;
        originalSiteElement.caption = siteElement.answer2caption;
        originalSiteElement.link_text = siteElement.answer2link_text;
      }

      // Dont use the question, otherwise we end up in a loop.
      // Also, don't animate in since the element will already be on the screen
      // Also, don't record the view since it's already been recorded
      originalSiteElement.use_question = false;
      originalSiteElement.animated = false;
      originalSiteElement.dontRecordView = true;
      originalSiteElement.view_condition = 'immediately';

      // Remove the siteElement and show the original in non preview environments
      if (!HB.CAP.preview) {
        siteElement.remove();
        // also remove siteElement object from HB.siteElementsOnPage array
        HB.siteElementsOnPage.splice(HB.siteElementsOnPage.indexOf(siteElement), 1);
        HB.addToPage(originalSiteElement);
      }
    };

    // If showResponse is set the preview environments, skip right to showing the response
    if (HB.CAP.preview && HB.showResponse) {
      siteElement.displayResponse(HB.showResponse);
      siteElement = originalSiteElement;
    }

    return siteElement;
  }

  return {
    questionifySiteElement
  };

});
