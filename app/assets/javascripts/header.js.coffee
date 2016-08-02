$ ->
  $(document.body).on "click", (evt) ->
    $dropdown = $(evt.target).closest("header .dropdown-wrapper")
    if $dropdown.length
      $dropdown.toggleClass("activated")

    $("header .dropdown-wrapper.activated").not($dropdown).removeClass("activated")