task start_server: :environment do
    bundle exec "puma"
end