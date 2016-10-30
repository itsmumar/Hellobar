HelloBar.PreviewView = Ember.View.extend({

  classNames: ['preview-wrapper'],

  //-----------  Color Thief  -----------#

  formatRGB(rgbArray) {
    rgbArray.push(1);
    return rgbArray;
  },

  didInsertElement() {
    let colorThief = new ColorThief();
    let image = $('.preview-image-for-colorpicker').get(0);

    return imagesLoaded(image, () => {
        let dominantColor = this.formatRGB(colorThief.getColor(image));
        let colorPalette = colorThief.getPalette(image, 4).map(color => this.formatRGB(color));

        this.set('controller.dominantColor', dominantColor);
        return this.set('controller.colorPalette', colorPalette);
      }
    );
  }
});
