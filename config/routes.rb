ActionController::Routing::Routes.draw do |map|
  map.resources :events
  
#  map.resources :links
  map.resources :entities, :has_many => [:links]
#  map.resources :entities do |entity|
#    entity.resources :links
#  end

  map.connect 'acknowledge_flows', :controller => 'acknowledge_flow', :action => 'list',:conditions => {:method => :get}
  map.connect 'acknowledge_flow/:currency/:declaring_account/:accepting_account', :controller => 'acknowledge_flow', :action => 'show',:conditions => {:method => :get}, :defaults => { :declaring_account => '', :accepting_account => '' }
  map.connect 'acknowledge_flow/:currency', :controller => 'acknowledge_flow', :action => 'ack', :conditions => {:method => :post}

  map.connect 'contexts/new', :controller => 'contexts', :action => 'new',:conditions => {:method => :get}
  map.connect 'contexts', :controller => 'contexts', :action => 'create', :conditions => {:method => :post}
  map.connect 'accounts/new', :controller => 'accounts', :action => 'new',:conditions => {:method => :get}
  map.connect 'accounts', :controller => 'accounts', :action => 'create', :conditions => {:method => :post}
  map.connect 'currencies/new', :controller => 'currencies', :action => 'new',:conditions => {:method => :get}
  map.connect 'currencies/join', :controller => 'currencies', :action => 'join',:conditions => {:method => :get}
  map.connect 'currencies/join', :controller => 'currencies', :action => 'join_request',:conditions => {:method => :post}
  map.connect 'currencies', :controller => 'currencies', :action => 'create', :conditions => {:method => :post}

  map.connect ':entity_type.:format', :controller => 'entities'
  map.connect ':entity_type', :controller => 'entities'
  map.connect ':entity_type/:id.:format', :controller => 'entities', :action => 'show'
  map.connect ':entity_type/:id', :controller => 'entities', :action => 'show'

  
#  map.resources :accounts, :controller => "entities"
  

  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
