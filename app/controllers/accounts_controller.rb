class AccountsController < ApplicationController

  # GET /accounts/new
  def new
  end
  
  # POST /accounts/
  def create
    @event = Event.create(
     {:event_type => "CreateAccount",
      :specification => {
        "parent_context" => params[:parent_context],
        "name" => params[:name],
        "account_specification" => {
          "description" => params[:description]
        }
       }.to_yaml
     }
    )
    if @event.enmesh && @event.save
      flash[:notice] = 'The account was created!'
      params[:name] = ''
      params[:description] = ''
    end
    render :action => "new"
  end
end
