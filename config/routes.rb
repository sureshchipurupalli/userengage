require 'resque/server'
require 'resque/status_server'

UserEngage::Application.routes.draw do
  devise_for :users, :controllers => { :sessions => 'sessions', :registrations => 'registrations', :confirmations => 'confirmations' }
  root :to => "home#index"
  get 'myaccount' => 'account#index'
  get 'changepassword' => 'home#change_password'
  post 'update_password' => 'home#update_password'

# public site routes
  get '/register/success' => 'home#register_success'
  get '/confirmation/success' => 'home#confirmation_success'
  post '/register/newsletter' => 'home#register_newsletter'

  resources :organisations do
    post 'organisation/set' => 'organisations#setCurrentOrganisaton', as: 'set'
  end

  resources :apps do
    get 'push_notification_settings' => 'apps#push_notification_settings'
    post 'android_settings' => 'apps#save_android_pn_settings'
    post 'ios_settings' => 'apps#save_ios_pn_settings'
    get 'ios_pn_certificate' => 'apps#view_ios_pn_certificate'
  end

  resources :crash_reports do
    get 'crash_reports' => 'crash_reports#crash_reports', :on => :member
  end

  resources :feedbacks do
    get 'reply' => 'feedbacks#reply'
    post 'postreply' => 'feedbacks#postreply'
    get 'details' => 'feedbacks#details'
  end

  resources :feedback_categories do

  end

  resources :organisation_users do

  end

  resources :app_users do

  end


  resources :push_notification_users do

  end

  resources :push_notification_groups do
    get "group_notifications" => "push_notification_groups#group_notifications", :on => :collection
  end

  resources :push_notifications do
    post "groups_filters" => "push_notifications#groups_filters", :on => :collection
    post "add_pn_user" => "push_notifications#add_pn_user", :on => :collection
    post "delete_pn_user" => "push_notifications#delete_pn_user", :on => :collection
    post "send" => "push_notifications#send_notifications_to_pn_users", :on => :collection
  end

  get 'create_campaign_content' => 'push_notifications#create_campaign_content'
  post 'save_campaign_details' => 'push_notifications#save_campaign_details'
  post 'push_notification_message' => 'push_notifications#save_pn_message'
  get 'select_users' => 'push_notifications#select_pn_users'
  post 'save_filtered_users' => 'push_notifications#save_filtered_users'
  get 'preview_and_schedule' => 'push_notifications#preview_and_schedule'
  post 'save_and_send' => 'push_notifications#save_and_send'
  get 'campaign_success' => 'push_notifications#campaign_success'
  post 'filter_users_by_platform' => 'push_notifications#filter_users_by_platform'
  post 'filter_users_by_model' => 'push_notifications#filter_users_by_model'
  post 'filter_users_by_version' => 'push_notifications#filter_users_by_version'
  get 'create_campaign_content' => 'push_notifications#create_campaign_content'


# API Routes
  scope 'api/:api_id' do # API route should contains api/:api-version
    scope module: 'api' do #create api folder in controllers and create api related controllers under api directory
      get 'api' => 'home#api'
      scope 'push_notifications' do
        post 'register_user' => 'push_notifications#register_user'
        post 'send' => 'push_notifications#send_notifications'
        post 'pause_push_notifications' => 'push_notifications#pause_push_notifications'
        post 'resume_push_notifications' => 'push_notifications#resume_push_notifications'
      end
      scope 'crash' do
        match 'submit' => 'crash_report#save', via: [:post, :put]
      end
      scope 'feedback' do
        get 'categories' => 'feedback#categories'
        post 'create' => 'feedback#create'
        get 'test' => 'feedback#test'
      end
    end
  end

  mount Resque::Server.new, at: "/resque"

end
