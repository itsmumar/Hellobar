namespace :dev do
  desc "Creates a temp site with site script at specified location\n rake dev:test_site[95, '~/Desktop/test.html']"
  task :test_site, [:site_id, :file_path] => :environment do |t, args|
    s = Site.find(args[:site_id])

    str = <<-EOS
      <html>
      <head>
      <style></style>
      </head>
      <body style="background-color: #FFFFFF;">


      <a onclick="console.log(‘BUTTON PUSHED')">HERE</a>
      <div style="height:500px;">Content</div>
      <div style="height:500px;">Content</div>
      Content
      <script>
    EOS

    str += s.script_content
    str += "</script></body></html>"
    File.open(args[:file_path], 'w+') { |file| file.write(str) }
  end
end
