$ ->

  $('#add-user').click (event) ->
    new AddTeamMemberModal().open();

  $('body').on 'click', '.change-permission', (event) ->
    event.preventDefault()

    $element = $(this)
    $cell         = $element.parents('td')
    siteID        = $cell.data('site-id')
    userID        = $cell.data('user-id')
    membershipID  = $cell.data('site-membership-id')
    role          = $element.data('option')

    data = {
      site_membership: {
        user_id: userID,
        site_id: siteID,
        role: role
      }
    }

    if membershipID && role == "none"
      $.ajax
        type: 'DELETE'
        url: "/sites/#{siteID}/site_memberships/#{membershipID}"
        data: data
        error: (xhr, status, error) ->
          # toggle the class and text back to original and render any error
          displayErrors(xhr.responseJSON.site_memberships)
        success: (xhr, status) ->
          $cell.removeData('site-membership-id')
          $cell.removeAttr('data-site-membership-id')
          updateCell($cell, "none")
    else if membershipID
      $.ajax
        type: 'PUT'
        url: "/sites/#{siteID}/site_memberships/#{membershipID}"
        data: data
        error: (xhr, status) ->
          displayErrors(xhr.responseJSON.site_memberships)
        success: (xhr, status) ->
          updateCell($cell, xhr.role)
    else
      $.ajax
        type: 'POST'
        url: "/sites/#{siteID}/site_memberships"
        data: data
        error: (xhr, status) ->
          displayErrors(xhr.responseJSON.site_memberships)
        success: (xhr, status) ->
          $cell.data('site-membership-id', xhr.id)
          updateCell($cell, xhr.role)

  updateCell = ($cell, role) ->
    $cell.find("span").text(role)
    $cell.find(".role-icon").removeClass("admin owner none").addClass(role)

  displayErrors = (errors) ->
    $(".flash-block").remove()
    errorText = errors.reduce (a, b) -> "#{a}<br>#{b}"
    flashBlock = $("<div class='flash-block error'><i class='icon-close'></i></div>")
    flashBlock.prepend(errorText)
    $('.error_container').prepend(flashBlock)

    setTimeout ( ->
      flashBlock.addClass('show')
    ), 300

    flashBlock.find('.icon-close').click (event) ->
      flashBlock.removeClass('show')
      setTimeout ( ->
        flashBlock.remove()
      ), 500
