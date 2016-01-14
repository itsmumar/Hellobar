//= require hellobar.base
//= require site_elements/site_element

var context = describe;

describe("SiteElement", function() {

  describe("#imagePlacementClass", function() {
    siteElement = null;
    beforeEach(function() {
      siteElement = new HB.SiteElement({});
    });

    context("when image_url is not present", function() {
      it("returns an empty string", function() {
        expect(siteElement.imagePlacementClass()).toEqual("");
      });
    });

    context("when image_url is present", function() {
      it("returns 'image-' + image_url", function() {
        siteElement.image_url = "www.something.com/blah.jpg";
        siteElement.image_placement = "left"
        expect(siteElement.imagePlacementClass()).toEqual("image-left");
      });
    });
  });

  describe("questions and answers", function() {
    siteElement = null;
    beforeEach(function() {
      siteElement = new HB.SiteElement({});
      siteElement.w = {
        contentWindow: {'document': document },
      };
    });

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
        siteElement.displayQuestion();
        expect(emailForm.style.display).toEqual("none");
      });

      it("hides any social links", function () {
        siteElement.displayQuestion();
        expect(social.style.display).toEqual("none");
      });

      it("replaces the headline with a question", function () {
        expect(headline.textContent).toEqual("headline before replacement");
        siteElement.displayQuestion();
        expect(headline.textContent).toEqual("the question");
      });

      it("shows the answer choices", function () {
        siteElement.displayQuestion();
        expect(answers.style.display).toEqual("inline-block");
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
        siteElement.displayQuestion();
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
        siteElement.displayResponse(1);
        expect(headline.textContent).toEqual("Welcome back!");
      });

      it("replaces the question with the response", function () {
        siteElement.displayResponse(1);
        expect(headline.textContent).toEqual("Welcome back!");
      });

      it("replaces the caption with a new caption", function () {
        siteElement.displayResponse(1);
        expect(caption.textContent).toEqual("new caption, innit");
      });

      it("shows the existing email form", function () {
        siteElement.displayResponse(1);
        expect(emailForm.style.display).toEqual("");
      });

      it("shows the social links", function () {
        siteElement.displayResponse(1);
        expect(social.style.display).toEqual("");
      });

      it("hides the answers and shows a new cta", function () {
        siteElement.displayResponse(1);
        elements = document.body.children;
        last_element = elements[elements.length - 1];
        expect(document.querySelector('#hb-answers').style.display).toEqual('none');
        expect(last_element).toEqual(responseCta1);
      });

    });

  });


});
