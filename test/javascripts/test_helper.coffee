# Teaspoon includes some support files, but you can use anything from your own support path too.
#= require support/sinon

# PhantomJS (Teaspoons default driver) doesn't have support for Function.prototype.bind, which has caused confusion.
# Use this polyfill to avoid the confusion.
#= require support/bind-poly
#
# Deferring execution
# If you're using CommonJS, RequireJS or some other asynchronous library you can defer execution. Call
# Teaspoon.execute() after everything has been loaded. Simple example of a timeout:
#
Teaspoon.defer = true
setTimeout(
  ->
    # Inject QUnit
    HelloBar.setupForTesting()
    HelloBar.injectTestHelpers()

    Ember.run.debounce = (context, myFunction, timeout) ->
      myFunction.call(context)

    Teaspoon.execute()
  , 2000
  # If you don't wait long enough, Ember won't be loaded up. 2 seconds minimum.
)

#
# Matching files
# By default Teaspoon will look for files that match _test.{js,js.coffee,.coffee}. Add a filename_test.js file in your
# test path and it'll be included in the default suite automatically. If you want to customize suites, check out the
# configuration in config/initializers/teaspoon.rb
#
# Manifest
# If you'd rather require your test files manually (to control order for instance) you can disable the suite matcher in
# the configuration and use this file as a manifest.
#
# For more information: http://github.com/modeset/teaspoon
#
# You can require your own javascript files here. By default this will include everything in application, however you
# may get better load performance if you require the specific files that are being used in the test that tests them.
#= require application

