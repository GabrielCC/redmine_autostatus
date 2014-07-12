# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
resources :departments
resources :resources
resources :issue_resources

post 'resources/settings/trackers', :to => 'resources#trackers'
post 'resources/settings/workflows', :to => 'resources#workflows'

match 'projects/:project_id/resources', :to => 'project_resources#create', :via => [:post]
match 'projects/:project_id/resources', :to => 'project_resources#index', :via => [:get]