module "editor colors",
  setup: ->
    @route = getModule("route:application")
    visit "settings"   

mobileButton = -> find(".toggle-mobile a")

asyncTest "it can toggle the mobile button", ->
  expect(2)
  click(mobileButton()).andThen =>
    ok $("#hellobar-preview-container").hasClass('hellobar-preview-container-mobile')
    click(mobileButton()).andThen =>
      ok !$("#hellobar-preview-container").hasClass('hellobar-preview-container-mobile')
      QUnit.start()
