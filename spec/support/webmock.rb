require 'addressable/uri'

# allow `=` and `/` chars for oauth params like:
#   WjzcP1v6eToTGGFm5wAVijdoQ5Q= and
#   qQ1gJ/xXJaAP5aTcl9NBlA==
Addressable::URI::CharacterClasses::UNRESERVED << '\\=\\/'
Addressable::Template.send :remove_const, :UNRESERVED
Addressable::Template::UNRESERVED =
  "(?:[#{ Addressable::URI::CharacterClasses::UNRESERVED }]|%[a-fA-F0-9][a-fA-F0-9])".freeze

require 'webmock/rspec'
