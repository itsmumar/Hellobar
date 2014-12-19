$ ->
  $(".unassigned-wordpress-bars > div").draggable
    axis: "y"
    revert: "invalid"
    revertDuration: 100

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
      droppable.find(".drop-area").droppable
        drop: (event, ui) ->
          droppable.find(".wordpress-bar-holder").append(ui.draggable.css("top", 0))
          if $(".unassigned-wordpress-bars .wordpress-bar").length < 1
            # enable primary form button if all bars have been assigned to sites
            $("form.user-migration-multiple-bars button").prop("disabled", false)

      $("p.instructions").html("Drag your bars to your site. <a class='add-site'>Click here to add another site.</a>")

      bindAddSite($("a.add-site"))

      form.hide()

  $("form.user-migration-multiple-bars").submit (event) ->
    event.preventDefault()

    $(event.target).find("button").prop("disabled", true)

    sites = []

    $(event.target).find(".wordpress-bar-holder").each (i, holder) ->
      site = {
        url: $(holder).data("site-url")
        timezone: $(holder).data("site-timezone")
        bar_ids: []
      }

      $(holder).find(".wordpress-bar").each (i2, bar) ->
        site.bar_ids.push($(bar).data("bar-id"))

      sites.push(site)

    $.ajax
      type: "POST"
      url: $(event.target).attr("action")
      data: {sites: sites}
      success: (data) ->
        window.location = data.url
