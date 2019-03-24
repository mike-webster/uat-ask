
require 'time'

class InstancesController < ApplicationController
  skip_before_action :verify_authenticity_token
  ERR_V_MESSAGE = "Sorry, I think you forgot something..."
  ERR_ASK_INCOMPLETE = "please provide all required fields\n_(type `/uat-help` for more information)_"
  ERR_ASK_UAT = "please provide iggy/waldo/learnable/mainsite"
  ERR_ASK_FEATURE = "please provide a feature name - this tells lily what you want to put on UAT"
  ERR_ASK_DESC = "please provide a description - tell lily what you're trying to do"

  def ask_for_instance
    # need username originating request, name of type of uat
    # optional: description of feature
    errors = InstancesController.validate_ask(params["text"])

    unless errors.nil?
      # slack needs a 200 to display the error to the user :/
      render status: 200, body: errors, content_type: "application/json"
      return
    end

    username = params["user_name"]
    ps = params["text"].split(",")
    uat_env = ps[0] || ""
    user_id = params["user_id"]
    gatekeeper_id = APP_CONFIG["uat_gatekeeper"]
    user_response = "I'm asking now, I'll let you know what they say :loading:"

    message_to_gatekeeper = "Hey, `@#{username}` would like to know if there's a UAT instance open for `#{uat_env}`"
    message_to_gatekeeper << "\n----- ----- ----- -----\n** Feature: #{ps[1] || ''}\n** Description: #{ps[2] || ''}\n----- ----- ----- -----"
    message_to_gatekeeper2 = "UAT instances:\n" + get_instance_report

    bot_token = APP_CONFIG["slack_bot_token"]
    SlackClient.send_uat_bot_message(user_id, user_response, bot_token)
    SlackClient.send_uat_bot_message(gatekeeper_id, message_to_gatekeeper, bot_token)
    SlackClient.send_uat_bot_message(gatekeeper_id, message_to_gatekeeper2, bot_token)

    Rails.logger.info({
      :event => "ask_for_instance",
      :params => request.params,
    })

    render status: 200, body: nil
  end

  def add_instance
    name = params["name"]
    feature = params["feature"]
    desc = params["description"]
    to_whom = params["assigned_to"]

    if name.nil? || name.empty?
      render :status => 400, :body => "{\"msg\":\"please supply instance name\"}"
      return
    end

    i = Instances.new({
      :name => name,
      :feature => feature,
      :description => desc,
      :assigned_to => to_whom,
      :updated => Time.now.utc,
    })
    i.save!

    Rails.logger.info({
      :event => "created new instance",
      :instance => i,
    })

    render :status => 200, :body => "#{get_instance_report}"
  end

  def healthcheck
    render status:200, body: "ok"
  end

  def update_instance
    requesting_user = params["user_id"]
    unless admins.include?(requesting_user)
      Rails.logger.warn({
        :event => "unauthorized decline request",
        :params => params,
      })

      render status: 403, body: "unauthorized"

      return
    end

    payload = params["text"]
    if payload.empty?
      Rails.logger.info({
        :event => "unable to parse update",
        :params => params,
      })

      render status: 400, body: "unable to parse update"

      return
    end

    payload = payload.split(",")
    name = payload[0] unless payload[0].blank?
    to_whom = payload[1] unless payload[1].blank?
    feature = payload[2] unless payload[2].blank?
    description = payload[3] unless payload[3].blank?

    i = Instances.where(:name => name).first

    if name.nil? || i.nil?
      Rails.logger.info({
        :event => "update record not found",
        :params => params,
      })

      render status: 400, body: "record for update not found"

      return
    end

    i.feature = feature || "master"
    i.description = description
    i.assigned_to = to_whom
    i.updated = Time.now.utc
    i.save!

    message = "Sounds good!"

    unless to_whom.blank?
      bot_token = APP_CONFIG["slack_bot_token"]

      su = SlackClient.get_username_by_email(to_whom.strip+"@#{APP_CONFIG["slack_email_domain"]}.com",bot_token)

      if su.nil?
        Rails.logger.error({
          :event => "failed to retrieve slack user by username",
          :username => to_whom,
          :params => params,
        })

        render status: 500, body: "failed to retrieve user from slack - couldn't notify"

        return
      end

      resp = "You got it! You can have `#{i.name}`. Please don't forget to let us know when you're done!"

      SlackClient.send_uat_bot_message(su, resp, bot_token)
      message << " I'll let them know."
    end

    render status: 200, body: message

    rescue => e
      Rails.logger.error({
        :event => "shit! error in update",
        :error => e,
        :backtrace => e.backtrace,
      })

      render status: 500, body: "something bad happened. I'm on it."
  end

  def decline_request
    requesting_user = params["user_id"]
    unless admins.include?(requesting_user)
      Rails.logger.warn({
        :event => "unauthorized decline request",
        :params => params,
      })

      render status: 403, body: "unauthorized"

      return
    end

    payload = params["text"]
    if payload.empty?
      Rails.logger.info({
        :event => "unable to parse decline request",
        :params => params,
      })

      render status: 400, body: "unable to parse decline request"

      return
    end

    payload = payload.split(",")
    username = payload[0] unless payload[0].blank?
    message = payload[1] unless payload[1].blank?
    bot_token = APP_CONFIG["slack_bot_token"]

    su = SlackClient.get_username_by_email(username.strip+"@#{APP_CONFIG["slack_email_domain"]}.com",bot_token)

    if su.nil?
      Rails.logger.info({
        :event => "unable to pass decline request - can't find user",
        :params => params,
      })

      render status: 400, body: "couldn't find user :("

      return
    end

    SlackClient.send_uat_bot_message(su, message, bot_token)

    Rails.logger.info({
      :event => "send decline message",
      :params => params,
      :user => su,
      :message => message,
    })

    render status: 200, body: nil
  end

  def user_done
    requesting_user = params["user_id"]
    # TODO: figure out how to verify that this is either an admin OR
    #       that the user_id matches the user the instance is attached to.
    instance_name = params["text"]
    if instance_name.blank?
      Rails.logger.info({
        :event => "unable to parse user done",
        :params => params,
      })

      render status: 400, body: "unable to parse update - please ask lily to handle this manually"

      return
    end

    i = Instances.where(:name => instance_name).first

    if instance_name.nil? || i.nil?
      Rails.logger.info({
        :event => "update record not found",
        :params => params,
      })

      render status: 400, body: "instance not found matching the name: #{instance_name}, please provide a valid instance name"

      return
    end

    i.feature = nil
    i.description = nil
    i.assigned_to = nil
    i.updated = Time.now.utc
    i.save!

    message = "OK - You're all done!!"

    render status: 200, body: message
  end

  def help_info
    instance_names = []
    Instances.all.each do |i|
      instance_names << i.name
    end
    
    message = "Ask For UAT Commands:\n\n"
    message << "_ (all lists are comma delimited) _\n"
    message << "1.) `/uat-ask [#{instance_names.join("/")}], [feature_name], [description]`\n"
    message << "    This can be used by anyone to request a UAT instance.\n"
    message << "    - [#{instance_names.join("/")}] is used to specify which app needs the UAT environment.\n"
    message << "    - [feature_name] is the name of the branch you would like to move to UAT.\n"
    message << "    - [description] is a quick description of what the branch is doing.\n"
    message << "    The gatekeeper will get a notification that a request has been made and when they approve or decline the request the person who made the request will receive a notification with some additional information.\n\n"
    message << "2.) `/uat-approve [instance_name], [assignee], [feature_name], [description]`\n"
    message << "    This is used by the gatekeeper to approve a request for a UAT instance.\n"
    message << "    _Anyone other than the gatekeeper will receive a 403._\n"
    message << "    - [instance_name] is required and must match an existing instance name.\n"
    message << "    - [assignee] is optional but must match a valid slack username in your organization (without the '@') if provided. If left blank, the assignee will be cleared in the database.\n"
    message << "    - [feature_name] is optional. Use this to keep track of what branch is loaded on each UAT instance. If left blank, the feature_name will default to 'master'.\n"
    message << "    - [description] is optional. Use this for any notes you have.\n\n"
    message << "3.) `/uat-decline [username], [message to user]`\n"
    message << "    This is used by the gatekeeper to decline a request for a UAT instance.\n"
    message << "    _Anyone other than the gatekeeper will receive a 403._\n"
    message << "    - [username] is required and must match a valid slack username (without the '@').\n"
    message << "    - [message to user] is whatever message the gatekeeper wants to convey along with the 'decline' of the request.\n\n"
    message << "4.) `/uat-done` [instance_name]\n"
    message << "    This is used by anyone to tell the gatekeeper that they can give someone else the UAT instance you were using.\n"
    message << "    - [instance_name] is used to specify which existing instance the user has finished using.\n"
    message << "5.) `/uat-report`\n"
    message << "    This can be used by the gatekeeper to see the current status of all UAT instances.\n"
    message << "--) Active instance_names:\n    "

    Instances.all.each do |i|
      message << "#{i.name}, "
    end

    message << "\n\n!! If you need any more help, or have any suggestions, feel free to DM the gatekeeper" 

    render status: 200, body: message
  end

  def list_instances
    unless admins.include?(params["user_id"])
      Rails.logger.warn({
        :event => "unauthorized decline request",
        :params => params,
      })

      render status: 403, body: "unauthorized"

      return
    end

    render :status => 200, :body => get_instance_report
  end

  def send_reminders
    # TODO: figure out a better way to authenticate this
    static_password = "dont$p@mM3"

    if params["token"] != static_password
      Rails.logger.warn({
        :event => "unauthorized decline request",
        :params => params,
      })

      render status: 403, body: "unauthorized"

      return
    end

    bot_token = APP_CONFIG["slack_bot_token"]

    Instances.all.each do |i|
      next if i.assigned_to.nil?
      
      su = SlackClient.get_username_by_email(i.assigned_to.strip+"@#{APP_CONFIG["slack_email_domain"]}.com",bot_token)
      if Time.now.utc - i.updated.localtime("+00:00") > 1.day
        message = "Hey! We're just checking in on your UAT instance - are you still using `#{i.name}`?\n"
        resp = SlackClient.send_uat_bot_reminder(su, message, bot_token)
      end
    end
  end

  # This is for the "send_reminders" functionality
  def user_response
    Rails.logger.info(:event => "action_response", :response => params["payload"].class)

    begin
      payload = ActiveSupport::JSON.decode(params["payload"])
      user = payload["user"]
      actions = payload["actions"]
      id = user["id"]
      value = actions[0]["value"]

      if value == "done"
        # TODO:
        #  - I think we might need to hide the instance name in the value? Or maybe another field?
        #  - Once I can identify the instance that's "done", retrieve it from the database and
        #    mark it as vacant.
        #  - After successfully updating the instance, send lily a message letting her know what happened.
      elsif value == "not_done"
        render :status => 200, :body => "No problem!"

        return
      else
        # this... shouldn't be possible
      end
    rescue StandardError => e
      Rails.logger.error(:event => "user_response_crash", :error => e, :backtrace => e.backtrace)
      return nil
    end

    render :status => 200, :body => "Thanks for the update!"
  end

  private

  # This method takes the "text" param from the slack slash
  # command and makes sure the required information was provided.
  # If there are any errors - a string is returned. Otherwise, nil.
  def self.validate_ask(params_text)
    if params_text.blank?
      return format_errors(ERR_V_MESSAGE, ERR_ASK_INCOMPLETE)
    end
    # so... I think the way this will work is just an
    # ordered, comma delimited list... so the values
    # will just need to match up
    payload = params_text.split(",")
    errors = ""
    if payload.count < 3
      return format_errors(ERR_V_MESSAGE, ERR_ASK_INCOMPLETE)
    end

    unless ["iggy","waldo", "learnable", "mainsite"].include?(payload[0].downcase)
      errors << ERR_ASK_UAT
    end

    unless payload[1].length > 0
      unless errors.empty?
          errors << "\n"
      end
      errors << ERR_ASK_FEATURE
    end

    unless payload[2].length > 0
      unless errors.empty?
          errors << "\n"
      end
      errors << ERR_ASK_DESC
    end

    return nil if errors.empty?

    format_errors(ERR_V_MESSAGE, errors)
  end

  def self.format_errors(msg, errors)
    "{\"text\": \"#{msg}\",\"attachments\":[{\"text\":\"#{errors}\"}]}"
  end

  def admins
   APP_CONFIG["admin_slack_ids"]
 end

  def auth
    # TODO: move auth here and put into a before filter
  end

  def get_instance_report
    # TODO: Maybe work on formatting this better?
    rep = "== == == == == == == == ==\n"
    rep += "==== Instance Report =====\n"
    rep += "== == == == == == == == ==\n"

    Instances.all.each_with_index do |i,c|
      rep += "== Name: `#{i.name}`\n"
      rep += "== Feature: `#{i.feature}`\n"
      rep += "== Description: `#{i.description}`\n"
      rep += "== Assigned To: `#{i.assigned_to}`\n"
      rep += "== When: `#{(i.updated.localtime("+06:00")) unless i.updated.nil?}`\n"
      rep += "== == == == == == == == ==\n"
    end

    rep
  end
end
