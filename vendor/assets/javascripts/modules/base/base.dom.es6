hellobar.defineModule('base.dom', [], function () {

  function forAllDocuments(callback) {
    if (callback) {
      callback(document);
      var iframes = document.getElementsByTagName('iframe') || [];
      Array.prototype.forEach.call(iframes, function (iframe) {
        try {
          var iframeDocument = iframe.contentDocument;
          callback(iframeDocument);
        } catch (e) {
          // We're fully ignoring iframe cross-origin restriction exception (it's represented with DOMException)
          // and print warning for anything else
          if (!(e instanceof DOMException)) {
            console.warn(e);
          }
        }
      });
    }
  }

  function runOnDocumentReady(callback) {
    var eventName = 'DOMContentLoaded';
    var eventHandler = function () {
      callback && callback();
      document.removeEventListener(eventName, eventHandler);
    };
    if (document.body) {
      callback && setTimeout(callback, 0);
    } else {
      document.addEventListener(eventName, eventHandler);
    }
  }

  /**
   * Adds the CSS class to the target element
   * @param element {Element}
   * @param className {string}
   */
  function addClass(element, className) {
    element = $(element);
    if (element.className.indexOf(className) < 0) {
      element.className += ' ' + className;
    }
  }


  /**
   * Removes the CSS class from the target element
   * @param element {Element}
   * @param className {string}
   */
  function removeClass(element, className) {
    element = $(element);
    // Get all the CSS class names and then add them
    // back by building a new array minus the target CSS class name
    var classNames = element.className.split(' ');
    var newClassNames = [];
    for (var i = 0; i < classNames.length; i++) {
      if (classNames[i] !== className) {
        newClassNames.push(classNames[i]);
      }
    }
    element.className = newClassNames.join(' ');
  }


  /**
   * Adds/removes CSS class for the target element
   * @param element {Element}
   * @param className {string}
   * @param shouldBeSet {boolean} if true then CSS class should be added otherwise CSS class should be removed
   */
  function setClass(element, className, shouldBeSet) {
    shouldBeSet ? addClass(element, className) : removeClass(element, className);
  }

  // Returns the element or looks it up via getElementById
  function $(idOrElement) {
    if (typeof(idOrElement) === 'string')
      return document.getElementById(idOrElement.replace('#', ''));
    else
      return idOrElement;
  }

  // Takes the given element and "shakes" it a few times and returns
  // it to its original style and positioning. Used to shake the
  // email field when it is invalid.
  function shake(element) {
    (function (element) {
      var velocity = 0;
      var acceleration = -0.1;
      var maxTravel = 1;
      // Store the original position
      var origPosition = element.style.position;
      var origX = parseInt(element.style.left, 0) || 0;
      var x = origX;
      var numShakes = 0;
      // Set the positioning to relevant
      element.style.position = 'relative';
      var interval = setInterval(function () {
        velocity += acceleration;
        if (x - origX >= maxTravel && acceleration > 0)
          acceleration *= -1;
        if (x - origX <= -maxTravel && acceleration < 0) {
          numShakes += 1;
          acceleration *= -1;
        }
        x += velocity;
        if (numShakes >= 2 && x >= origX) {
          clearInterval(interval);
          element.style.left = origX + 'px';
          element.style.position = origPosition;
        }
        element.style.left = Math.round(x) + 'px';
      }, 5);
    })($(element));
  }


  function animateIn(element, time) {
    // HTML 5 supported so show the animation
    if (typeof element.classList == 'object') {
      element.classList.remove('hb-animateOut');
      element.classList.add('hb-animated');
      element.classList.add('hb-animateIn');
    }

    showElement(element); // unhide if hidden
  }

  function animateOut(element, callback) {
    // HTML 5 supported so show the animation
    if (typeof element.classList == 'object') {
      element.classList.remove('hb-animateIn');
      element.classList.add('hb-animated');
      element.classList.add('hb-animateOut');
    } // else just hide
    else {
      hideElement(element);
    }

    // if a callback is given, wait for animation then execute
    if (typeof(callback) == 'function') {
      window.setTimeout(callback, 250);
    }
  }

  // Delays & restarts wiggle animation before & after mousing over bar
  function wiggleEventListeners(context) {
    var element = context.querySelector('#hellobar');
    var cta = element.querySelector('.hellobar-cta');

    element.addEventListener('mouseenter', function () {
      removeClass(cta, 'wiggle');
    });

    element.addEventListener('mouseleave', function () {
      setTimeout(function () {
        addClass(cta, 'wiggle');
      }, 2500);
    });
  }

  function hideElement(element) {
    if (element == null) {
      return
    } // do nothing
    if (element.length == undefined) {
      element.style.display = 'none';
    } else {
      for (var i = 0; i < element.length; ++i) {
        element[i].style.display = 'none';
      }
    }
  }

  function showElement(element, display) {
    if (element == null) {
      return
    } // do nothing
    if (typeof display === 'undefined') {
      display = 'inline';
    }
    if (element.length == undefined) {
      element.style.display = display;
    } else {
      for (var i = 0; i < element.length; ++i) {
        element[i].style.display = display;
      }
    }
  }


  /**
   * @module base.dom {object} Performs DOM-related operations (traversing, modifying etc)
   */
  return {

    /**
     * Runs specified callback for all the documents - main HTML document and iframe documents (those that we have access to).
     * @param callback {function}
     */
    forAllDocuments,

    /**
     * Runs specified callback once DOM has been loaded
     * @param callback {function}
     */
    runOnDocumentReady,
    addClass,
    removeClass,
    setClass,
    shake,
    animateIn,
    animateOut,
    wiggleEventListeners,
    showElement,
    hideElement,
    $
  };

});
