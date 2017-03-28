hellobar.defineModule('elements', ['base.storage', 'base.serialization', 'base.site'], function (storage, serialization, site) {

  let siteElementData = {};

  // TODO it was setSiteElementData previously
  // Sets the siteElement attribute specified by the key and siteElementID to the value in HB.cookies
  // Also updates the cookies via HB.saveCookies
  function setData(siteElementID, key, value) {
    if (!siteElementID)
      return;
    siteElementID = siteElementID + '';
    var s = siteElementData;
    if (!s[siteElementID])
      s[siteElementID] = {};
    s[siteElementID][key] = value;
    //HB.saveCookies();
    saveToStorage();
  }


  // TODO it was getSiteElementData previously
  // Gets the siteElement attribute from HB.cookies specified by the siteElementID and key
  function getData(siteElementID, key) {
    if (!siteElementID)
      return;
    siteElementID = siteElementID + '';
    var s = siteElementData;
    if (!s[siteElementID])
      s[siteElementID] = {};
    return s[siteElementID][key];
  }


  function saveToStorage() {
    var array = [];
    for (var k in siteElementData) {
      var value = siteElementData[k];
      if (typeof(value) != 'function') {
        array.push(k + '|' + serialization.serialize(value));
      }
    }
    storage.setValue('hbs_' + site.siteId(), array.join('^'), 365 * 5);
  }

  function loadFromStorage() {
    var array = (storage.getValue('hbs_' + site.siteId()) || '').split('^');
    for (var i = 0; i < array.length; i++) {
      var raw = array[i];
      if (raw) {
        var partIndex = raw.indexOf('|');
        var id = raw.slice(0, partIndex);
        var data = raw.slice(partIndex + 1);
        siteElementData[id] = serialization.deserialize(data);
      }
    }
  }

  return {
    initialize: () => {
      loadFromStorage();
    },
    getData,
    setData
  };

});

