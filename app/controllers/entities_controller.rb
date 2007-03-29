class EntitiesController < ApplicationController
  before_filter :check_for_entity_type
  # GET /entities
  # GET /entities.xml
  def index
    @entities = Entity.find(:all,@conditions)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @entities.to_xml }
    end
  end

  # GET /entities/1
  # GET /entities/1.xml
  def show
    @entity = Entity.find(params[:id],@conditions)

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @entity.to_xml }
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

    respond_to do |format|
      if @entity.update_attributes(params[:entity])
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
