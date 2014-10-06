namespace :improve_suggestions do
  desc "Generate improve suggestions for all sites"
  task :generate_all => :environment do
    Site.all.each { |s| ImproveSuggestion.generate_all(s) }
  end
end
