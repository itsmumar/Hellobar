$ ->
  $(".unassigned-wordpress-bars > div").draggable(
    axis: "y"
    revert: "invalid"
    revertDuration: 100
  )

  bindAddSite = (element) ->
    element.unbind("click")

    element.click (event) ->
      $("a.add-site").hide()
      $("form.add-site-for-migration").show()

  $("form.add-site-for-migration button").click (event) ->
    event.preventDefault()

    form = $(event.target).parents("form:first")
    data = form.serializeJSON()


    if data.site_url.match(/^[^@\s]+\.[^@\s]+$/)
      # site url looks like a url
      primaryForm = $("form.user-migration-multiple-bars")
      primaryForm.find(".unassigned-wordpress-bars").show()
      primaryForm.find("button").show()
      primaryForm.find("a.add-site").show()

      template = Handlebars.compile($("#user-migration-drop-area-template").html())
      droppable = $(template(siteURL: data.site_url, siteTimezone: data.site_timezone))
      droppable.insertBefore(primaryForm.find(".unassigned-wordpress-bars"))
      droppable.find(".drop-area").droppable(
        drop: (event, ui) ->
          window.foo = event
          window.bar = ui
          droppable.find(".wordpress-bar-holder").append(ui.draggable.css("top", 0))
      )

      $("p.instructions").html("Drag your bars to your site. <a class='add-site'>Click here to add another site.</a>")

      bindAddSite($("a.add-site"))

      form.hide()
