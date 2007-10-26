######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################


# TODO the implementation of the filtering parameters here is totally non-scalable
# gotta figure out how to fix that.

class EntitiesController < ApplicationController

  before_filter :check_for_entity_type
  # GET /entities
  # GET /entities.xml
  def index
    @entities = Entity.find(:all,@conditions)

    if params[:entity_type] == "currencies"
      if params[:used_by]
        account_omrl = OMRL.new(params[:used_by]).to_s
        @entities = @entities.collect {|e| e.links.any?{|l| l.link_type == 'is_used_by' && l.omrl == account_omrl} ? e : nil }.reject {|e| e == nil}
      end
    end

    if params[:entity_type] == "flows"
      @entities = Flow.filter(@entities,params)
    end

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @entities.to_xml(:methods => [:omrl]) }
    end
  end
  


  # GET /entities/1
  # GET /entities/1.xml
  def show
    if params[:id].to_i == 0
      @entity = Entity.find_by_omrl(params[:id])
    else
      @entity = Entity.find(params[:id],@conditions)
    end

    if @entity
      respond_to do |format|
        summary_list = []
        if @entity.valid_credentials(:password => params[:password])
          summary_list << 'count' << 'volume'
        end
        params.each { |key,value| summary_list << $1 if key =~/^account_(.*)/ && Entity.find_by_omrl($1).valid_credentials(:password => value) }
        format.html # show.rhtml
        format.xml  { render :xml => @entity.to_xml(:methods => [:omrl],:summaries => summary_list) }
      end
    else
      render_404
    end
  end

  # GET /entities/new
  def new
    @entity = Entity.new
  end

  # GET /entities/1;edit
  def edit
    @entity = Entity.find(params[:id])
  end

  # POST /entities
  # POST /entities.xml
  def create
    e = params[:entity].clone
    @entity = Entity.new(e)

    respond_to do |format|
      if @entity.save
        flash[:notice] = 'Entity was successfully created.'
        format.html { redirect_to entity_url(@entity) }
        format.xml  { head :created, :location => entity_url(@entity) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @entity.errors.to_xml }
      end
    end
  end

  # PUT /entities/1
  # PUT /entities/1.xml
  def update
    @entity = Entity.find(params[:id])
    
    @entity.set_password(params[:password]) if params[:password]
    @entity.attributes = params[:entity]
    respond_to do |format|
      if @entity.save
        flash[:notice] = 'Entity was successfully updated.'
        format.html { redirect_to entity_url(@entity) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @entity.errors.to_xml }
      end
    end
  end

  # DELETE /entities/1
  # DELETE /entities/1.xml
  def destroy
    @entity = Entity.find(params[:id])
    @entity.destroy

    respond_to do |format|
      format.html { redirect_to entities_url }
      format.xml  { head :ok }
    end
  end
  
  private
 
  def check_for_entity_type
    @conditions =  (params[:entity_type]) ? {:conditions => ["entity_type = ? ", params[:entity_type].singularize]} : {}
#    render_text @conditions
  end
  
end
