//= require hellobar.base
var context = describe;

describe("HB", function() {

  var element;
  var formElement;
  var siteElement;
  var thankYouText;

  beforeEach(function() {
    HB.loadCookies();
    HB_SITE_ID = 1234;

    element = document.createElement("div");
    element.innerHTML = '<div class="hb-headline-text"></div><div class="hb-input-wrapper"><div class="hb-secondary-text"></div></div> \
                         <div id="hb-fields-form"> \
                           <div class="hb-input-block builtin-email"><input id="f-builtin-email"></div> \
                           <div class="hb-cta">Click Here</div> \
                         </div>'
    document.body.appendChild(element);

    formElement = document.getElementById("hb-fields-form");
    thankYouText = 'Thank you for signing up!'

    siteElement = {w: {contentDocument: document}, subtype: 'email'};
  });

  afterEach(function() {
    document.body.removeChild(element);
    HB_SITE_ID = null;
  });

  describe(".submitEmail", function() {
    context("is not redirection", function() {
      context("uses the free default thank you message", function() {
        beforeEach(function() {
          siteElement.use_free_email_default_msg = true;
        });

        it("sets the button text to 'click here'", function () {
          HB.submitEmail(siteElement, formElement, element, "", "", false, "");
          var buttonElement = document.getElementsByClassName('hb-cta')[0];
          expect(buttonElement.textContent).toEqual("Click Here");
        });

        it("sets the button href to the http://www.hellobar.com", function () {
          HB.submitEmail(siteElement, formElement, element, thankYouText, false, "", "");
          var buttonElement = document.getElementsByClassName('hb-cta')[0];
          expect(buttonElement.href).toMatch("http://www.hellobar.com?hbt=emailSubmittedLink&sid=1234");
        });

        it("hides the email inputs", function() {
          HB.submitEmail(siteElement, formElement, element, thankYouText, "", false, "");
          var inputBlock = document.getElementsByClassName('hb-input-block')[0];
          expect(inputBlock.style.display).toEqual('none');
        });

        it("hides the secondary text", function() {
          HB.submitEmail(siteElement, formElement, element, thankYouText, "", false, "");
          var inputBlock = document.getElementsByClassName('hb-secondary-text')[0];
          expect(inputBlock.style.display).toEqual('none');
        });
      });

      context("thank you message is supplied", function() {
        var thankYouText = "ABC 123";

        beforeEach(function() {
          siteElement.use_free_email_default_msg = false;
        });

        it("sets the headline text to the supplied thank you message", function () {
          HB.submitEmail(siteElement, formElement, element, thankYouText, "", false, "");
          var buttonElement = document.getElementsByClassName('hb-cta')[0];
          expect(element.textContent).toEqual(thankYouText);
        });

        it("removes the entire input wrapper", function () {
          HB.submitEmail(siteElement, formElement, element, thankYouText, "", false, "");
          var inputBlock = document.getElementsByClassName('hb-input-wrapper')[0];
          expect(inputBlock.style.display).toEqual('none');
        });

        it("hides the secondary text", function() {
          HB.submitEmail(siteElement, formElement, element, thankYouText, "", false, "");
          var inputBlock = document.getElementsByClassName('hb-secondary-text')[0];
          expect(inputBlock.style.display).toEqual('none');
        });
      });

      context("email address is valid", function() {
        it("calls recordEmail with the name and email", function() {
          spyOn(HB, 'recordEmail');
          var email = 'myEmail@test.com';
          var name = 'My Name';

          HB.submitEmail(siteElement, formElement, element, thankYouText, "", false, "");
          expect(HB.recordEmail).toHaveBeenCalledWith(siteElement, email, name, jasmine.any(Function));
        });
      });

      context("email address is not valid", function() {
        it("does not call recordEmail", function() {
          spyOn(HB, 'recordEmail');
          spyOn(HB, 'shake');

          HB.submitEmail(siteElement, {value: 'aol.com'}, {value: 'My Name'}, element, "", false, "");
          expect(HB.recordEmail).not.toHaveBeenCalled();
        });

        it("shakes the email input", function() {
          spyOn(HB, 'recordEmail');
          spyOn(HB, 'shake');
          var emailInput = {value: 'aol.com'};

          HB.submitEmail(siteElement, emailInput, {value: 'My Name'}, element, "", false, "");
          expect(HB.shake).toHaveBeenCalledWith(emailInput);
        });
      });
    });

    context("emailSubmitted callback", function() {
      it("triggers the emailSubmitted callback", function() {
        spyOn(HB, 'trigger')

        HB.submitEmail(siteElement, formElement, thankYouText, element, "", false, "");
        expect(HB.trigger).toHaveBeenCalledWith('emailSubmitted', jasmine.any(Object), "myEmail@test.com", undefined);
      });
    });
  });
});
