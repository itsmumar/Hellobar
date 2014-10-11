$ ->
  $('nav.global-sidebar input, a.create-variation').on 'click', (event) ->
    # if site has maxed out site elements
    if window.site && window.site.capabilities.at_site_element_limit
      event.preventDefault()

      new UpgradeAccountModal().open() # ask them to upgrade
