# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_rememberthemilk_session_id'
  
  helper_method :full_url, :get_error
	
	def get_cookie(name)
	  cookies[name]
  end
  
  def full_url
    CONFIG['fousa']
  end
  
  def get_error
    session["error"]
  end
end
