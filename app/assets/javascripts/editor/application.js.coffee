#= require jquery
#= require jquery_ujs
#= require zeropad.jquery
#= require jstz-1.0.4.min
#= require underscore

#= require colorpicker
#= require color_thief
#= require jquery_dropper

#= require handlebars
#= require handlebars_helpers
#= require ember

#= require_self
#= require ./store

#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./components
#= require ./routes/step-routes
#= require_tree ./routes
#= require_tree ./templates
#= require ./../modal
#= require_tree ./../modals
#= require ./../upgrade_modal_initializer

#= require ./router

#-----------  Application Initiation  -----------#

window.HelloBar = Ember.Application.create
  rootElement: "#ember-root"

#-----------  Debounce/Throttle Observers  -----------#

Ember.debouncedObserver = (keys..., time, func) ->  
  Em.observer ->
    Em.run.debounce @, func, time
  , keys...

Ember.throttledObserver = (keys..., time, func) ->  
  Em.observer ->
    Em.run.throttle @, func, time
  , keys...

#-----------  Preview Injection  -----------#

HB.injectAtTop = (element) ->
  container = HB.$("#hellobar-preview-container")

  if container.children[0]
    container.insertBefore(element, container.children[0])
  else
    container.appendChild(element)

#-----------  Set Application Height  -----------#

$ ->

  setHeight = ->
    height = $(window).height() - $('.header-wrapper').height()
    $('#ember-root').height(height)

  $(window).resize ->
    setHeight()

  setHeight()
