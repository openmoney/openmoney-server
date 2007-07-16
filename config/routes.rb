ActionController::Routing::Routes.draw do |map|
  map.resources :events
  
#  map.resources :links
  map.resources :entities, :has_many => [:links]
#  map.resources :entities do |entity|
#    entity.resources :links
#  end


  map.connect 'acknowledge_flow/:currency', :controller => 'acknowledge_flow', :action => 'show',:conditions => {:method => :get}
  map.connect 'acknowledge_flow/:currency', :controller => 'acknowledge_flow', :action => 'ack', :conditions => {:method => :post}

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
