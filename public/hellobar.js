// Legacy support for Helo Bar v1 bars (Wordpress)
var HelloBar = function (a, b) {
  // sets site element ID so that we know which one to show
  window.HB_element_id = b;

  // Load site script specially crafted for old Wordpress users
  var url = "//my.hellobar.com/" + a + "_" + b + ".js"
  var element = document.createElement("script");
  element.setAttribute("src", url);

  // Attach it to the document's body
  var f = function () {
    if (document && document.body && document.body.appendChild)
      document.body.appendChild(element);
    else
      setTimeout(f, 50);
  }

  f();
};
