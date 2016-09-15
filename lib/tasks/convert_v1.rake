namespace :convert_v1 do
  desc 'Force convert HB 1.0 users'
  task :all => :environment do
    # Find all 1.0 users
    c = 0
    t = 0
    Hello::WordpressUser.each do |user|
      t += 1
      puts "Processed #{t} users. Converted #{c} users" if t % 100 == 0
      print "#{user.email}..."
      if user.converted?
        puts "already converted"
        next
      end
      if user.bars.length == 0
        puts "no bars"
        next
      end
      begin
        new_user, new_site, new_bars = user.force_convert
        puts "imported #{new_bars.length} bars"
        c += 1
      rescue StandardError => e
        puts "ERRO: #{e.message}"
      end
    end
    break
  end
end
