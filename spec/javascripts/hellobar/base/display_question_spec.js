//= require hellobar.base

describe("HB", function() {
  var emailForm;
  var social;
  var headline;
  var captionwrapper;
  var caption;
  var cta;
  var question;
  var answers;
  var responseText1;
  var responseCta1;

  function attachElementWithClass(name, text) {
    var element = document.createElement("div");
    element.className = name;
    if (text) { element.textContent = text }
    document.body.appendChild(element);
    return element;
  };

  function attachElementWithId(id, text) {
    var element = document.createElement("div");
    element.id = id;
    if (text) { element.textContent = text }
    document.body.appendChild(element);
    return element;
  };

  beforeEach(function() {
    emailForm = attachElementWithClass("hb-input-wrapper");
    social    = attachElementWithClass("hb-social-wrapper");
    headline  = attachElementWithClass("hb-headline-text", "headline before replacement");
    captionwrapper = attachElementWithClass("hb-text-wrapper");
    caption =  document.createElement("div");
    caption.className = 'hb-secondary-text';
    caption.textContent = "original caption";
    captionwrapper.appendChild(caption);
    cta       = attachElementWithClass("hb-cta");
    question  = attachElementWithId('hb-question', "the question");
    answers   = attachElementWithId("hb-answers");
    answers.textContent = '<span><a id="hb-answer1" class="hb-cta">Yes</a></span><span><a id="hb-answer2" class="hb-cta">No</a></span>'
    answers.style.display = "none";
  });

  describe(".displayQuestion", function() {
    afterEach(function() {
      document.body.removeChild(emailForm);
      document.body.removeChild(social);
      document.body.removeChild(headline);
      document.body.removeChild(captionwrapper);
      document.body.removeChild(cta);
      document.body.removeChild(question);
      document.body.removeChild(answers);
    });

    it("hides an existing email form", function () {
      HB.displayQuestion(document, headline, cta);
      expect(emailForm.style.display).toEqual("none");
    });

    it("hides any social links", function () {
      HB.displayQuestion(document, headline, cta);
      expect(social.style.display).toEqual("none");
    });

    it("replaces the headline with a question", function () {
      expect(headline.textContent).toEqual("headline before replacement");
      HB.displayQuestion(document, headline, cta);
      expect(headline.textContent).toEqual("the question");
    });

    it("shows the answer choices", function () {
      HB.displayQuestion(document, headline, cta);
      expect(answers.style.display).toEqual("");
    });
  });

  describe(".displayResponses", function() {
    beforeEach(function() {
      responseText1 = attachElementWithId('hb-answer1-response');
      var rtspan = document.createElement("span");
      rtspan.textContent = "Welcome back!";
      responseText1.appendChild(rtspan);
      responseCta1 = document.createElement("a");
      responseCta1.textContent = "Shop Now";
      responseText1.appendChild(responseCta1);
      captionText1 = attachElementWithId('hb-answer1-caption');
      captionText1.textContent = "new caption, innit";
      HB.displayQuestion(document, headline, cta);
    });

    afterEach(function() {
      document.body.removeChild(emailForm);
      document.body.removeChild(social);
      document.body.removeChild(headline);
      document.body.removeChild(captionwrapper);
      if(document.querySelector('.hb-cta')) { document.body.removeChild(cta); }
      if(document.querySelector('#hb-question')) { document.body.removeChild(question); }
      if(document.querySelector('#hb-answers')) { document.body.removeChild(answers); }
      document.body.removeChild(responseText1);
      document.body.removeChild(responseCta1);
    });

    it("replaces the question with the response", function () {
      HB.displayResponse(document, 1);
      expect(headline.textContent).toEqual("Welcome back!");
    });

    it("replaces the question with the response", function () {
      HB.displayResponse(document, 1);
      expect(headline.textContent).toEqual("Welcome back!");
    });

    it("replaces the caption with a new caption", function () {
      HB.displayResponse(document, 1);
      expect(caption.textContent).toEqual("new caption, innit");
    });

    it("shows the existing email form", function () {
      HB.displayResponse(document, 1);
      expect(emailForm.style.display).toEqual("");
    });

    it("shows the social links", function () {
      HB.displayResponse(document, 1);
      expect(social.style.display).toEqual("");
    });

    it("replaces the answers with a new cta", function () {
      HB.displayResponse(document, 1);
      elements = document.body.children;
      last_element = elements[elements.length - 1];
      expect(document.querySelector('#hb-answers')).toEqual(null);
      expect(last_element).toEqual(responseCta1);
    });

  });

});
