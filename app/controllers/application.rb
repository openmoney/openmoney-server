# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  def render_404 
    respond_to do |format| 
      format.html { render :file => "#{RAILS_ROOT}/public/404.html", :status => '404 Not Found' } 
      format.xml  { render :nothing => true, :status => '404 Not Found' } 
    end 
    true 
  end
end
