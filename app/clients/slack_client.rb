require 'json'

class SlackClient
  def self.send_uat_bot_reminder(user_id, message, token)
    return nil if user_id.nil? || message.nil? || token.nil?

    url = "https://slack.com/api/chat.postMessage"

    # TODO: get this to work
    payload = {
      "channel": "#{user_id}",
      "text": "#{message}",
      "attachments": [{
        "text": "Are you done with you UAT instance?",
        "callback_id": "instance-reminder",
        "delete_original": "true",
        "attachment_type": "default",
        "actions": [{
          "name": "done",
          "text": "Done!",
          "type": "button",
          "value": "done"
        },
        {
          "name": "not_done",
          "text": "Still Working!",
          "type": "button",
          "value": "not_done"
        }]
      }]
    }
    resp = Excon.post(url,
      :headers => {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{token}",
      },
      :body => payload)
  end

  def self.send_uat_bot_message(user_id, message, token)
    return nil if user_id.nil? || message.nil? || token.nil?

    url = "https://slack.com/api/chat.postMessage"
    payload = "{\"channel\":\"#{user_id}\",\"text\":\"#{message}\"}"

    resp = Excon.post(url,
      :headers => {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{token}",
      },
      :body => payload)
  end

  def self.get_username_by_email(email, token)
    url = "https://slack.com/api/users.lookupByEmail?email=" + email
    resp = Excon.post(url,
      :headers => {
        "Content-Type" => "application/x-www-form-urlencoded",
        "Authorization" => "Bearer #{token}",
      })

    if resp.status != 200
      Rails.logger.warn({
        :event => "failed external call: get_username_by_email",
        :status => resp.status,
        :body => resp.body,
      })

      return nil
    end

    body = JSON.parse(resp.body)
    unless body["ok"]
      Rails.logger.warn({
        :event => "failed to find user",
        :email => email,
        :status => resp.status,
        :body => resp.body,
      })

      return nil
    end

    Rails.logger.info({
      :event => "successful external call",
      :response => resp.body,
    })

    return body["user"]["id"]

    rescue => e
      Rails.logger.error({
        :event => "failed parsing response",
        :error => e,
      })
  end
end
