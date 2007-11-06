# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  def render_status(code)
    respond_to do |format| 
      format.html { render :file => "#{RAILS_ROOT}/public/#{code}.html", :status => code } 
      format.xml  { render :nothing => true, :status => code } 
    end 
    true 
  end
end
