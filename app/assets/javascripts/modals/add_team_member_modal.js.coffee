class @AddTeamMemberModal extends Modal

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#add-team-member-template").html())
    @$modal = $(@template())
    @$modal.appendTo($("body"))
    @$form = @$modal.find("form")
    super(@$modal)

  open: ->
    @_bindSiteChange(@$modal)
    super

  _bindSiteChange: (object) ->
    object.find("#site_id").change (e) =>
      @$form.attr('action', "/sites/#{e.target.value}/site_memberships/invite")
