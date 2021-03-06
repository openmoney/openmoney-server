######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

class AccountsController < ApplicationController

  # GET /accounts/new
  def new
  end
  
  # POST /accounts/
  def create
    @event = Event.create(
     {:event_type => "CreateAccount",
      :specification => {
        "credentials" => {params[:parent_context] => {:tag => params[:tag], :password=>params[:password]}},
        "access_control" => {:tag => params[:steward_tag], :password => params[:steward_password], :authorities => '*', :defaults=>['accepts']},
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
      params.clear
    end
    render :action => "new"
  end
end
