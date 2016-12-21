//= require hellobar.base
var context = describe;

describe("HB", function() {

  var element;
  var siteElement;

  beforeEach(function() {
    HB.loadCookies();
    HB_SITE_ID = 1234;

    element = document.createElement("div");
    element.innerHTML = '<div class="hb-headline-text">This is Headline</div> \
                         <div class="hb-input-wrapper"> \
                          <div class="hb-secondary-text"></div> \
                          <div id="hb-fields-form"> \
                            <div class="hb-input-block builtin-email"> \
                              <input id="f-builtin-email" value="email@example.com"> \
                            </div> \
                            <div class="hb-input-block builtin-name"> \
                              <input id="f-builtin-name" value="Test User"> \
                            </div> \
                            <div class="hb-cta" href="Javascript:;">Submit</div> \
                          </div> \
                         </div>'
    document.body.appendChild(element);

    formElement = document.getElementById("hb-fields-form");
    targetSiteElement = document.getElementsByClassName("hb-headline-text")[0];
    thankYouText = 'Thank you for signing up!';
    emailField = document.getElementById('f-builtin-email');

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
          HB.submitEmail(siteElement, formElement, targetSiteElement, thankYouText, "", false, "");
        });

        it("sets the button text to 'click here'", function () {
          var buttonElement = document.getElementsByClassName('hb-cta')[0];
          expect(buttonElement.textContent).toEqual("Click Here");
        });

        it("sets the button href to the http://www.hellobar.com", function () {
          var buttonElement = document.getElementsByClassName('hb-cta')[0];
          expect(buttonElement.href).toEqual('http://www.hellobar.com?hbt=emailSubmittedLink&sid=1234');
        });

        it("hides the email inputs", function() {
          var inputBlock = document.getElementsByClassName('hb-input-block')[0];
          expect(inputBlock.style.display).toEqual('none');
        });

        it("hides the secondary text", function() {
          var inputBlock = document.getElementsByClassName('hb-secondary-text')[0];
          expect(inputBlock.style.display).toEqual('none');
        });
      });

      context("thank you message is supplied", function() {
        beforeEach(function() {
          siteElement.use_free_email_default_msg = false;
          HB.submitEmail(siteElement, formElement, targetSiteElement, thankYouText, "", false, "");
        });

        it("sets the headline text to the supplied thank you message", function () {
          var thankYouElement = document.getElementsByClassName('hb-headline-text')[0];
          expect(thankYouElement.textContent).toEqual(thankYouText);
        });

        it("removes the entire input wrapper", function () {
          var inputBlock = document.getElementsByClassName('hb-input-wrapper')[0];
          expect(inputBlock.style.display).toEqual('none');
        });

        it("hides the secondary text", function() {
          var inputBlock = document.getElementsByClassName('hb-secondary-text')[0];
          expect(inputBlock.style.display).toEqual('none');
        });
      });

      context("email address is valid", function() {
        it("calls recordEmail with the name and email", function() {
          spyOn(HB, 'recordEmail');
          var email = emailField.value;
          var name  = document.getElementById('f-builtin-name').value;

          HB.submitEmail(siteElement, formElement, targetSiteElement, thankYouText, "", false, "");
          expect(HB.recordEmail).toHaveBeenCalledWith(siteElement, [email, name], jasmine.any(Function));
        });
      });

      context("email address is not valid", function() {
        beforeEach(function() {
          spyOn(HB, 'recordEmail');
          spyOn(HB, 'shake');
        });

        it("does not call recordEmail", function() {
          emailField.value = "";
          HB.submitEmail(siteElement, formElement, targetSiteElement, thankYouText, "", false, "");
          expect(HB.recordEmail).not.toHaveBeenCalled();
        });

        it("shakes the email input", function() {
          emailField.value = "aol.com";
          HB.submitEmail(siteElement, formElement, targetSiteElement, thankYouText, "", false, "");
          expect(HB.shake).toHaveBeenCalledWith(emailField);
        });
      });
    });

    context("emailSubmitted callback", function() {
      it("triggers the emailSubmitted callback", function() {
        spyOn(HB, 'trigger');

        var email = emailField.value;
        var name  = document.getElementById('f-builtin-name').value;

        HB.submitEmail(siteElement, formElement, targetSiteElement, thankYouText, "", false, "");
        expect(HB.trigger).toHaveBeenCalledWith('emailSubmitted', jasmine.any(Object), [email, name]);
      });
    });
  });
});
