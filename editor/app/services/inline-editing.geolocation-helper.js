let editorClosers = [];

function closeAllExistingEditors() {
  editorClosers.forEach((close) => close());
}

function showDefaultGeolocationEditor($target) {
  closeAllExistingEditors();
  const target = ($target && $target.length > 0) ? $target[0] : null;
  const rect = target.getBoundingClientRect();
  const geolocationType = $target.attr('data-hb-geolocation');
  const placeholder = `Input ${geolocationType}...`;
  const labelText = `Default ${geolocationType} name`;
  const html = `<div class="default-geolocation-editor"><label></label><input placeholder="${placeholder}"></div>`;
  const iframeDocument = target.ownerDocument;
  const documentBody = iframeDocument.body;
  const iframeWindow = iframeDocument.defaultView;
  const $editor = $(html).css({
    left: rect.left + 'px',
    top: (rect.top + 30) + 'px'
  }).appendTo(documentBody);
  $editor.find('label').text(labelText);
  $editor.find('input').val($target.attr('data-hb-geolocation-default'));
  setTimeout(() => {
    $editor.find('input').focus();
  }, 1);

  function syncData() {
    $target.attr('data-hb-geolocation-default', $editor.find('input').val());
  }

  $editor.on('click', (evt) => {
    evt.stopPropagation();
  });
  $editor.on('blur', 'input', (evt) => {
    syncData();
  });

  function close() {
    syncData();
    $editor.off('click');
    $editor.off('blur', 'input');
    $(window).off('click', windowClickHandler);
    (window !== iframeWindow) && $(iframeWindow).off('click', windowClickHandler);
    $editor.remove();
  }

  function windowClickHandler() {
    close();
  }

  $(window).on('click', windowClickHandler);
  (window !== iframeWindow) && $(iframeWindow).on('click', windowClickHandler);

  editorClosers.push(close);
}

export default {
  bindEvents($froalas) {
    $froalas
      .on('mousedown', '[data-hb-geolocation]', (evt) => evt.stopPropagation())
      .on('mouseup', '[data-hb-geolocation]', (evt) => evt.stopPropagation());
    $froalas.on('click', '[data-hb-geolocation]', (evt) => {
      evt.preventDefault();
      evt.stopPropagation();
      const $target = $(evt.currentTarget);
      showDefaultGeolocationEditor($target);
    });
  },

  unbindEvents($froalas) {
    $froalas.off('click', '[data-hb-geolocation]');
    $froalas.off('mousedown', '[data-hb-geolocation]');
    $froalas.off('mouseup', '[data-hb-geolocation]');
  }
};

