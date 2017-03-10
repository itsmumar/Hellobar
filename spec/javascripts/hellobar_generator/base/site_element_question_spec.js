//= require hellobar_script/hellobar.base
//= require site_elements/site_element
var context = describe;

describe("HB", function() {
  var siteElement;

  beforeEach(function() {
    HB.siteElementsOnPage = [];
    var siteElementData = {
      settings: { url: "" },
      use_question: true,
      template_name: "bar_traffic",
      headline: "ABC",
      question: "What do?",
      answer1: "Answer One",
      answer2: "Answer Two",
      answer1response: "Answer 1 Response",
      answer1caption: "Answer 1 Caption",
      answer1link_text: "Answer 1 Link Text",
      answer2response: "Answer 2 Response",
      answer2caption: "Answer 2 Caption",
      answer2link_text: "Answer 2 Link Text",
      id: "1"
    }

    siteElement = new HB.SiteElement(siteElementData);
    siteElement.dataCopy = siteElementData;

    spyOn(siteElement, 'attach');
  });

  describe("HB.addToPage", function() {
    context("element does not have a question", function() {
      it("does not questionify the site element", function () {
        siteElement.use_question = false;
        spyOn(HB, 'questionifySiteElement');
        HB.addToPage(siteElement);
        expect(HB.questionifySiteElement).not.toHaveBeenCalled();
      });
    });

    context("element has a question", function() {
      it("does not questionify the site element", function () {
        spyOn(HB, 'questionifySiteElement').and.returnValue(siteElement);
        HB.addToPage(siteElement);
        expect(HB.questionifySiteElement).toHaveBeenCalled();
      });
    });

    context("considering whether or not to add this to the page", function() {
      it("adds the element to the page if not added already", function() {
        siteElement.use_question = false;
        HB.addToPage(siteElement);

        expect(HB.siteElementsOnPage.length).toEqual(1);
      });

      it("does not add the element to the page if already added", function() {
        siteElement.use_question = false;
        HB.addToPage(siteElement);
        HB.addToPage(siteElement);

        expect(HB.siteElementsOnPage.length).toEqual(1);
      });
    });
  });

  describe("HB.findSiteElementOnPageById", function() {
    context("when element exists in array", function() {
      it("returns the element found", function() {
        HB.siteElementsOnPage.push(siteElement);
        var result = HB.findSiteElementOnPageById(siteElement.id);

        expect(result).toEqual(siteElement);
      });
    });

    context("when element does not exists in array", function() {
      it("returns null", function() {
        HB.siteElementsOnPage.push(siteElement);

        expect(HB.findSiteElementOnPageById("2")).toEqual(null);
      });
    });
  });

  describe("HB.questionifySiteElement", function() {
    it("returns a siteElement with the headline that is the question", function () {
      var result = HB.questionifySiteElement(siteElement);
      expect(result.headline).toEqual(siteElement.question);
    });

    it("sets the template to {type}_question", function () {
      var result = HB.questionifySiteElement(siteElement);
      expect(result.template_name).toEqual("bar_question");
    });

    it("removes any images from the result", function () {
      siteElement.image_url = "abc";
      var result = HB.questionifySiteElement(siteElement);
      expect(result.image_url).toEqual(null);
    });

    it("removes any caption from the result", function () {
      siteElement.caption = "abc";
      var result = HB.questionifySiteElement(siteElement);
      expect(result.caption).toEqual(null);
    });

    it("calls addToPage with the correct responses when triggering displayReponse with 1", function () {
      var result = HB.questionifySiteElement(siteElement);
      spyOn(HB, 'addToPage');
      result.displayResponse(1);

      expect(HB.addToPage).toHaveBeenCalledWith(jasmine.objectContaining({
        headline: siteElement.answer1response,
        caption: siteElement.answer1caption,
        link_text: siteElement.answer1link_text,
        template_name: siteElement.template_name
      }));
    });

    it("calls addToPage with the correct responses when triggering displayReponse with 2", function () {
      var result = HB.questionifySiteElement(siteElement);
      spyOn(HB, 'addToPage');
      result.displayResponse(2);

      expect(HB.addToPage).toHaveBeenCalledWith(jasmine.objectContaining({
        headline: siteElement.answer2response,
        caption: siteElement.answer2caption,
        link_text: siteElement.answer2link_text,
        template_name: siteElement.template_name
      }));
    });

    it("calls addToPage without animations when triggering displayReponse", function () {
      siteElement.animated = true;
      var result = HB.questionifySiteElement(siteElement);
      spyOn(HB, 'addToPage');
      result.displayResponse(2);

      expect(HB.addToPage).toHaveBeenCalledWith(jasmine.objectContaining({
        animated: false
      }));
    });

    it("calls addToPage, disabling tracking the view (since it's already been viewed)", function () {
      siteElement.animated = true;
      var result = HB.questionifySiteElement(siteElement);
      spyOn(HB, 'addToPage');
      result.displayResponse(2);

      expect(HB.addToPage).toHaveBeenCalledWith(jasmine.objectContaining({
        dontRecordView: true
      }));
    });

    it("calls addToPage with the view condition set to immediate", function () {
      siteElement.view_condition = 'wait-60';
      var result = HB.questionifySiteElement(siteElement);
      spyOn(HB, 'addToPage');
      result.displayResponse(2);

      expect(HB.addToPage).toHaveBeenCalledWith(jasmine.objectContaining({
        view_condition: 'immediately'
      }));
    });

    it("calls remove() on the result when triggering displayResponse", function () {
      var result = HB.questionifySiteElement(siteElement);
      spyOn(result, 'remove');
      result.displayResponse(2);

      expect(result.remove).toHaveBeenCalled();
    });

    context("callbacks", function() {
      beforeEach(function() {
        var result = HB.questionifySiteElement(siteElement);
        spyOn(HB, 'trigger');
        result.displayResponse(2);
      });

      it("triggers the answerSelected callback", function() {
        expect(HB.trigger).toHaveBeenCalledWith('answerSelected', 2);
      });

      it("triggers the answered callback", function() {
        expect(HB.trigger).toHaveBeenCalledWith('answered', jasmine.any(Object), 2);
      });
    });

  });
});
