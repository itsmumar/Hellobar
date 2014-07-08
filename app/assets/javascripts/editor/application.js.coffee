#= require jquery
#= require jquery_ujs

#= require color_thief
#= require jquery_dropper
#= require jquery_minicolors

#= require handlebars
#= require ember

#= require_self
#= require ./store

#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./components
#= require ./routes/step-routes
#= require_tree ./routes
#= require_tree ./templates

#= require ./router

#-----------  Application Initiation  -----------#

window.HelloBar = Ember.Application.create
  rootElement: "#ember-root"

#-----------  Set Application Height  -----------#

$ ->

  setHeight = ->
    height = $(window).height() - $('.header-wrapper').height()
    $('#ember-root').height(height)

  $(window).resize ->
    setHeight()

  setHeight()
