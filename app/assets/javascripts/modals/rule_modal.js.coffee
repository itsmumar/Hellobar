class RuleModal
  constructor: (@$modal) ->

  openModal: ->
    @$modal.addClass('open-modal')

  closeModal: ->
    # $(document).on 'keypress', (event) ->
    #   if event.keyCode == 27 # bind escape key
    @$modal.removeClass('open-modal')
  #   - bind to clicking outside of the target area
  #   - bind to the close button

  # renderCondition
  #   - 

  # isConflicted
  #   -

  # renderConflictMessage
  #   - adds a display class to the dialog box
