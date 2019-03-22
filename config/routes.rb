Rails.application.routes.draw do
  post '/instances/ask', to: 'instances#ask_for_instance'
  post '/instances/add', to: 'instances#add_instance'
  post '/instances/update', to: 'instances#update_instance'
  post '/instances/decline', to: 'instances#decline_request'
  post '/instances/help', to: 'instances#help_info'
  post '/instances/done', to: 'instances#user_done'
  post '/instances/report', to: 'instances#list_instances'
  post '/instances/remind', to: 'instances#send_reminders'
  post '/instances/user-response', to: 'instances#user_response'
end
