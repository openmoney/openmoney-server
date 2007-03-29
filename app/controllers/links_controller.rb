class LinksController < ApplicationController
  before_filter :find_entity

  # GET /links
  # GET /links.xml
  def index
    @links = Link.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @links.to_xml }
    end
  end

  # GET /links/1
  # GET /links/1.xml
  def show
    @link = Link.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @link.to_xml }
    end
  end

  # GET /links/new
  def new
    @link = Link.new
  end

  # GET /links/1;edit
  def edit
    @link = Link.find(params[:id])
  end

  # POST /links
  # POST /links.xml
  def create
    @link = Link.new(params[:link])

    respond_to do |format|
      if (@entity.links << @link)
        flash[:notice] = 'Link was successfully created.'
        furl = link_url(@entity,@link)
        format.html { redirect_to furl}
        format.xml  { head :created, :location => furl }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @link.errors.to_xml }
      end
    end
  end

  # PUT /links/1
  # PUT /links/1.xml
  def update
    @link = @entity.links.find(params[:id])

    respond_to do |format|
      if @link.update_attributes(params[:link])
        flash[:notice] = 'Link was successfully updated.'
        format.html { redirect_to link_url(@link) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @link.errors.to_xml }
      end
    end
  end

  # DELETE /links/1
  # DELETE /links/1.xml
  def destroy
    @link = @entity.links.find(params[:id])
    @link.destroy

    respond_to do |format|
      format.html { redirect_to links_url }
      format.xml  { head :ok }
    end
  end
end

private

def find_entity
  @entity_id = params[:entity_id]
  if (@entity_id)
    @entity = Entity.find(@entity_id)
  else
#    redirect_to entities_url unless @entity_id
  end
end