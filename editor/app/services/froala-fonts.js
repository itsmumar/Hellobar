import Ember from 'ember';

export default Ember.Service.extend({
  fontFamily() {
    return {
      "Arial,Helvetica,sans-serif": 'Arial',
      "Georgia,serif": 'Georgia',
      "Impact, Charcoal, sans-serif": 'Impact',
      "Lato,sans-serif": 'Lato',
      "Montserrat,sans-serif": 'Montserrat',
      "'Open Sans',sans-serif": 'Open Sans',
      "Oswald,sans-serif": 'Oswald',
      "'PT Sans',sans-serif": 'PT Sans',
      "'PT Serif',sans-serif": 'PT Serif',
      "Raleway, sans-serif": 'Raleway',
      "Roboto,sans-serif": 'Roboto',
      "Tahoma, Geneva, sans-serif": 'Tahoma',
      "'Times New Roman', Times, serif, -webkit-standard": 'Times New Roman',
      "Verdana, Geneva, sans-serif": 'Verdana'
    };
  },

  googleFonts() {
    return [
      'Lato',
      'Montserrat',
      'Open Sans',
      'Oswald',
      'PT Sans',
      'PT Serif',
      'Raleway',
      'Roboto'
    ]
  }
});
