# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

#resources :customers, :path => 'customers'

#get 'customers', :to => 'customers#index'
#match 'customers/bobo', :controller => 'customers', :action => 'bobo', :via => :get

#get 'customers/new', :to => 'customers#new'
#delete 'customers/destroy', :to => 'customers#destroy'
#get 'customers/import', :to => 'customers#import'
#post 'customers/edit', :to => 'customers#edit'
#get 'customers/show', :to => 'customers#show'


RedmineApp::Application.routes.draw do

  match '/customers/context_menu', :to => 'context_menus#customers', :as => 'customers_context_menu', :via => [:get, :post]
  match '/customers', :controller => 'customers', :action => 'destroy', :via => :delete
  resources :customers do
    collection do
      get 'acfind'
      get 'import'
      get 'autocomplete_for_customer'
      post 'match'
      post 'result'
    end
    member do
      get 'inactive'
      get 'active'
    end
  end
  resources :customers_reports do
    collection do
      get 'generate'
     end
  end

end