//= require hellobar_script/hellobar.base
var context = describe;

describe('HB', function () {
  describe('setTracking', function () {
    context('hb_ignore parameter is set', function () {
      it('sets disableTracking to true if the hb_ignore is true', function () {
        HB.setTracking('?hb_ignore=true');
        expect(HB.t(HB.gc('disableTracking'))).toEqual(true);
      });

      it('sets disableTracking to true if the hb_ignore is false', function () {
        HB.setTracking('?hb_ignore=false');
        expect(HB.t(HB.gc('disableTracking'))).toEqual(false);
      });

      it('sets disableTracking to true if the hb_ignore is anything other than true', function () {
        HB.setTracking('?hb_ignore=asdf');
        expect(HB.t(HB.gc('disableTracking'))).toEqual(false);
      });
    });

    context('hb_ignore parameter is not set', function () {
      it('leaves it as true', function () {
        HB.sc('disableTracking', true, 123456);
        HB.setTracking('?asdfasdf=true');
        expect(HB.t(HB.gc('disableTracking'))).toEqual(true);
      });

      it('leaves it as false', function () {
        HB.sc('disableTracking', false, 123456);
        HB.setTracking('?asdfasdf=true');
        expect(HB.t(HB.gc('disableTracking'))).toEqual(false);
      });
    });
  });
});
