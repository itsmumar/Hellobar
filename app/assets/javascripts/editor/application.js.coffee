#= require jquery
#= require jquery_ujs

#= require handlebars
#= require ember

#= require_self
#= require ./store

#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./routes
#= require_tree ./templates

#= require ./router

#-----------  Application Initiation  -----------#

window.HelloBar = Ember.Application.create
  rootElement: "#ember-root"
