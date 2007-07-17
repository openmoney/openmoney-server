class ContextsController < ApplicationController  
  # GET /contexts/new
  def new
  end
  
  # POST /contexts/
  def create
    @event = Event.create(
     {:event_type => "CreateContext",
      :specification => {
        "parent_context" => params[:parent_context],
        "name" => params[:cname],
        "context_specification" => {
          "description" => params[:description]
        }
       }.to_yaml
     }
    )
    if @event.enmesh && @event.save
      flash[:notice] = 'The context was created!'
      params[:name] = ''
      params[:description] = ''
    end
    render :action => "new"
  end
end