namespace :ember do
  desc 'Build Ember Application'
  task :build do
    on roles(:web) do
      execute "cd #{ fetch(:ember_app_path) } && ember build --environment=production >/dev/null"
    end
  end

  desc 'Move non digested specific fonts to public'
  task :move_non_digest_fonts do
    on roles(:web) do
      execute "cd #{ fetch(:release_path) } && cp app/assets/fonts/* public/assets/"
    end
  end
end
