# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Assets paths
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets')
Rails.application.config.assets.paths << Rails.root.join('lib', 'themes')
Rails.application.config.assets.paths << Rails.root.join('lib', 'script_generator')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += [/\.(?:svg|eot|woff|ttf)$/]
Rails.application.config.assets.precompile += %w[editor.css static.css admin.css editor/application.js ember.js *.css.erb *.css.sass.erb]
Rails.application.config.assets.precompile += %w[admin.js static.js jquery.minicolors.png]
Rails.application.config.assets.precompile += %w[hellobar.eot hellobar.woff hellobar.ttf hellobar.svg]
Rails.application.config.assets.precompile += %w[hellobar-icons.eot hellobar-icons.woff hellobar-icons.ttf hellobar-icons.svg]
Rails.application.config.assets.precompile += %w[glyphicons-halflings-regular.ttf glyphicons-halflings-regular.woff]
Rails.application.config.assets.precompile += %w[eyedropper.svg receipt.css site_elements_controller.js team.js]
Rails.application.config.assets.precompile += %w[editor/editor-require.js editor/editor.js editor/editor.css editor/vendor.js editor/vendor.css editor/vendor/fonts/*]

# Teaspoon
Rails.application.config.assets.precompile += %w[teaspoon.css teaspoon-*.js]
