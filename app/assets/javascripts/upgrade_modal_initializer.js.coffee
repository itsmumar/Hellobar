$ ->

  if window.location.hash.substring(1) == "migration-complete"
    new MigrationCompleteModal().open()
