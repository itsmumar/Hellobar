hellobar.defineModule('base.cdn.libraries', ['base.cdn'], function (cdn) {

  function useFontAwesome(doc) {
    const version = '4.4.0';
    cdn.addCss(`//cdnjs.cloudflare.com/ajax/libs/font-awesome/${version}/css/font-awesome.min.css`, doc);
  }

  function useFroala(doc) {
    useFontAwesome(doc);
    const version = '2.4.0';
    cdn.addCss(`//cdnjs.cloudflare.com/ajax/libs/froala-editor/${version}/css/froala_editor.min.css`, doc);
    cdn.addCss(`//cdnjs.cloudflare.com/ajax/libs/froala-editor/${version}/css/plugins/colors.min.css`, doc);
    cdn.addCss(`//cdnjs.cloudflare.com/ajax/libs/froala-editor/${version}/css/plugins/emoticons.css`, doc);
    cdn.addCss(`//cdnjs.cloudflare.com/ajax/libs/froala-editor/${version}/css/plugins/image.min.css`, doc);
  }

  function useAnimateCss(doc) {
    const version = '3.5.2';
    cdn.addCss(`//cdnjs.cloudflare.com/ajax/libs/animate.css/${version}/animate.min.css`, doc);
  }

  return {
    useFontAwesome,
    useFroala,
    useAnimateCss
  };

});
