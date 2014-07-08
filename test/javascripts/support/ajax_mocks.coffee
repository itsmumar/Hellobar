$.mockjax({
  url: /^\/sites\/([\d]+)\/site_elements\/([\d\-]+)\.json$/
  urlParams: ['siteID', 'siteElementID']
  contentType: 'text/json'
  response: (settings) ->
    siteID = settings.urlParams.siteID
    siteElementID = settings.urlParams.siteElementID
    {  
      id: 1
      element_subtype: "traffic"
      link_url: null
      message: "Hello. Add your message here."
      link_text: "Click Here"
      font: "Helvetica,Arial,sans-serif"
      background_color: "eb593c"
      border_color: "ffffff"
      button_color: "000000"
      link_color: "ffffff"
      text_color: "ffffff"
    }
})
