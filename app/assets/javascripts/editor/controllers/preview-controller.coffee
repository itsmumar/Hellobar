HelloBar.PreviewController = Ember.Controller.extend

  needs: ['application']

  isMobile    : Ember.computed.alias('controllers.application.isMobile')
  isPushed    : Ember.computed.alias('model.pushes_page_down')
  barSize     : Ember.computed.alias('model.size')
  barPosition : Ember.computed.alias('model.placement')    
  elementType : Ember.computed.alias('model.type')

  previewStyleString: ( ->
    if @get('isMobile')
      "background-image:url(#{@get('model.site_preview_image_mobile')})"
    else
      "background-image:url(#{@get('model.site_preview_image')})"
  ).property('isMobile', 'model.site_preview_image', 'model.site_preview_image_mobile')

  previewImageURL: ( ->
    if @get('isMobile')
      "#{@get('model.site_preview_image_mobile')}"
    else
      "#{@get('model.site_preview_image')}"
  ).property('isMobile', 'model.site_preview_image', 'model.site_preview_image_mobile')
