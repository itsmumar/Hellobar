HelloBar.SettingsModel = Ember.Object.create

  #-----------  Responses  -----------#

  linkURL: null

  feedbackEmail: null

  collectionSelection: null
  storageSelection: null
  socialSelection: null

  #-----------  Choices  -----------#

  collectionOptions: [
    {id: 1, text: 'Just email addressses'}
    {id: 2, text: 'Just names & locations'}
    {id: 3, text: 'Names, locaitons & emails'}
  ]

  storageOptions: [
    {id: 1, text: 'Store them in Hello Bar'}
    {id: 2, text: 'My own Google spreadsheet'}
    {id: 3, text: 'In da\' cloud, man'}
  ]

  socialOptions: [
    {id: 1, text: 'Tweet on Twitter'}
    {id: 2, text: 'Follow on Twitter'}
    {id: 3, text: 'Like on Facebook'}
    {id: 4, text: 'Share on LinkedIn'}
    {id: 5, text: '+1 on Google+'}
    {id: 6, text: 'Pin on Pinterest'}
    {id: 7, text: 'Follow on Pinterest'}
    {id: 8, text: 'Share on Buffer'}
  ]
