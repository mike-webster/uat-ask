require "#{Rails.root}/app/helpers/application_helper"
include ApplicationHelper

task get_slack_id: :environment do
    begin
        username = ENV['USERNAME']
        if username.nil?
            puts event: "early_termination", reason: "no_username"
        else

        bot_token = APP_CONFIG["slack_bot_token"]
        
        su = SlackClient.get_username_by_email(username.strip+"@#{APP_CONFIG["slack_email_domain"]}.com",bot_token)
        puts event: "retrieved_slack_id", id: su
        end
    rescue StandardError => e
        puts event: "fatal_error", error: r
    end
end