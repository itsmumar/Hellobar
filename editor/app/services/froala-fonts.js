import Ember from 'ember';

export default Ember.Service.extend({
  fontFamily() {
    return {
      "Arial,Helvetica,sans-serif": 'Arial',
      "Georgia,serif": 'Georgia',
      "Impact, Charcoal, sans-serif": 'Impact',
      "'Josefin Sans',sans-serif": 'Josefin Sans',
      "'Kanit', sans-serif": 'Kanit',
      "Lato,sans-serif": 'Lato',
      "'Libre Baskerville',sans-serif": 'Libre Baskerville',
      "Montserrat,sans-serif": 'Montserrat',
      "'Open Sans',sans-serif": 'Open Sans',
      "Oswald,sans-serif": 'Oswald',
      "'PT Sans',sans-serif": 'PT Sans',
      "'PT Serif',sans-serif": 'PT Serif',
      "Raleway, sans-serif": 'Raleway',
      "Roboto,sans-serif": 'Roboto',
      "'Sintony',sans-serif": 'Sintony',
      "'Source Sans Pro',sans-serif": 'Source Sans Pro',
      "Tahoma, Geneva, sans-serif": 'Tahoma',
      "\'Times New Roman\', Times, serif": 'Times New Roman',
      "Verdana, Geneva, sans-serif": 'Verdana'
    };
  },

  googleFonts() {
    return [
      'Josefin+Sans',
      'Lato',
      'Libre+Baskerville',
      'Kanit',
      'Montserrat',
      'Open Sans',
      'Oswald',
      'PT Sans',
      'PT Serif',
      'Raleway',
      'Roboto',
      'Sintony',
      'Source+Sans+Pro'
    ];
  }
});
