require 'tempfile'
require 'fileutils'

namespace :icons do
  desc 'compile custom icons from app/assets/icons into a font file'
  task :compile do
    puts 'Compiling icons...'
    puts `fontcustom compile`

    puts 'removing generated font-face definitions, font file linking will not work without asset-pipeline digests'
    icons_stylesheet = "#{ Rails.root }/app/assets/stylesheets/settings/_hellobar-icons.scss"
    no_font_face = Tempfile.new('no_font_face')

    begin
      File.open(icons_stylesheet, 'r') do |file|
        removing_lines = false

        file.each_line do |line|
          removing_lines = true if line =~ /^@font-face.*$|^@media screen and.*$/
          no_font_face.puts line unless removing_lines
          removing_lines = false if line =~ /^}$/
        end
      end
      no_font_face.close
      FileUtils.mv(no_font_face.path, icons_stylesheet)
    ensure
      no_font_face.close
      no_font_face.unlink
    end
  end
end
