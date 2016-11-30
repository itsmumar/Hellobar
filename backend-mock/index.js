const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());

const port = 3001;

const data = {
  newSiteElement: require('./data/newSiteElement.js')
};

app.get('/sites/:siteId/site_elements/new.json', function (req, res) {
  res.send(data.newSiteElement);
});

/*app.get('/sites/:siteId/site_elements/:siteElementId.json', function (req, res) {

});*/

app.listen(port, function () {
  console.log('Mock API started. Listening port ' + port);
});
