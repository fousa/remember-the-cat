ActionController::Routing::Routes.draw do |map|
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

  map.home '', :controller => "main", :action => "index"
  map.callback 'callback', :controller => "rtc", :action => "callback"
  map.rtc 'rtc', :controller => "rtc", :action => "overview"
  map.rtm 'rtm', :controller => "rtc", :action => "overview"
  map.undo 'rtc/undo', :controller => "rtc", :action => "undo"
  map.policy 'policy', :controller => "main", :action => "policy"
  map.feedback 'feedback', :controller => "main", :action => "feedback"

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:list/:id.:format'
  map.connect ':controller/:action/:list/:id'
end
