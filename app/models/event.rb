######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
#
######################################################################################
# Events are what happens to create the mesh that is the relationships of linked
# entities.
# The Event class is subclassed for each event type.
# Each event type must either pass a block to or override the enmesh method to implement
# what the event consists of, which is usually either the creation of a new entity, and
# or linking together of existing entities by creating new link objects.

class Event < ActiveRecord::Base
  Types = %w(CreateContext CreateCurrency CreateAccount JoinCurrency AcknowledgeFlow)

  validates_presence_of :event_type
  validates_presence_of :specification
  validates_inclusion_of :event_type, :in => Types
  
  include Specification
  
  ######################################################################################
  # this is a factory method that creates Events of the correct type if they have been
  # subclassed, otherwise it raises an exception
  def self.create(params)
    class_name = "Event::#{params[:event_type]}"
    begin
      class_name.constantize.new(params)
    rescue
      raise "Unknown event type: #{params[:event_type]}"
    end
  end
  
  ######################################################################################
  # the abstract act of enmeshing is simply to validate the specification of the event
  # and then (if it's valid) to yeild to the block which which can take enmeshment acations
  # and add further errors if they fail.
  def _enmesh(validations,attribute_name = :specification)
    validate_specification(validations,attribute_name)
    if errors.empty? 
      errs = []
      yield errs
      errors.add(attribute_name, "- enmeshing error: " << errs.join(",")) if !errs.empty?
    end
    errors.empty?
  end

  ######################################################################################
  # some events are entity creation events.  CreateEvent is a base class for all such events
  # it over-rides enmesh, accepting the entity type to be created, and defines a block
  # with which it calls the super-class "enmesh" method that actually does the creation of
  # the entity record.  If the creation of the entity is succesfull it in turns yields
  # to the callers block which can do something with the created entity.
  class CreateEvent < Event
    attr :created_entity
  
    def create_enmesh(entity_type,validations,attributes_for_entity=[])
      validations ||= {'name' => :required}
      _enmesh(validations) do |errs|
        
        # copy into the entity specification any named attributes in the specification
        # these are strictly speaking not necessary because though we could examine the mesh for
        # and figure out the information, it's much faster and easier to pull the data out of the 
        # entity itself.
        entity_specification = @specification["#{entity_type}_specification"]
        attributes_for_entity.each{|attrib| entity_specification[attrib] = @specification[attrib]}
        
        entity = Entity.new({:entity_type => entity_type,:specification => entity_specification.to_yaml})
        if (!entity.save)
          errs << "Error#{(entity.errors.count>1)? 's' : ''} creating entity: #{entity.errors.full_messages.join(',')}"
        else
          @created_entity = entity
          begin
            yield entity
          rescue Exception => e
            errs  << e.to_s # << e.backtrace
            entity.destroy
          end
        end
      end
    end
    
    ######################################################################################
    # Some entities when created must have a parent entity.  This method can be used by
    # any subclasses of Create event.  It sets up the standard validation for the specification
    # to include the parent entities omrl.  It also implements the block which
    # links the new entity to the parent entity
    def enmesh_parent_omrl(entity_type,extra_links_from = nil,extra_links_to = nil)
      validations = {'name' => :required, 'parent_context' => :required, "#{entity_type}_specification" => :required}
      extra_links_to.each {|spec,link_type| validations[spec] = :required} if extra_links_to.is_a?(Hash)
      extra_links_from.each {|spec,link_type| validations[spec] = :required} if extra_links_from.is_a?(Hash)

      # make sure parent context is the fully sepcified form by adding the period onto the end of it
      # if it's not already there.
      load_specification
      @specification['parent_context'] = "#{@specification['parent_context']}." if @specification['parent_context'] !~ /\.$/
      
      create_enmesh(entity_type,validations,['parent_context']) do |entity|
        create_link(@specification['parent_context'],entity.num_omrl,'names',"name: #{@specification['name']}")
        extra_links_from.each {|spec,link_type| create_link(entity.omrl,@specification[spec],link_type)}  if extra_links_from.is_a?(Hash)
        extra_links_to.each {|spec,link_type| create_link(@specification[spec],entity.omrl,link_type)}  if extra_links_to.is_a?(Hash)
      end
    end
  end

  ######################################################################################
  class CreateContext < CreateEvent
    def enmesh
      enmesh_parent_omrl 'context'
    end
  end

  ######################################################################################
  class CreateCurrency < CreateEvent
    def enmesh
      enmesh_parent_omrl('currency',{'originating_account' => 'originates_from'})
    end
  end

  ######################################################################################
  class CreateAccount < CreateEvent
    def enmesh
      enmesh_parent_omrl 'account'
    end
  end

  ######################################################################################
  class JoinCurrency < Event
    def enmesh
      _enmesh({'currency' => :required, 'account' => :required}) do |errs|
        begin
          create_link(@specification['currency'],@specification['account'],'is_used_by')
        rescue Exception => e
          errs  << e.to_s
        end
      end
    end
  end

  ######################################################################################
  class AcknowledgeFlow < CreateEvent
    def enmesh
      create_enmesh('flow',{'flow_specification' => :required,'declaring_account' => :required,'accepting_account' => :required,'currency' => :required},%w(declaring_account accepting_account currency)) do |entity|
        links = []
        begin
          entity_omrl = OMRL.new_flow(@specification['declaring_account'],entity.id).to_s
          { 'declaring_account'=>'declares',
            'accepting_account'=>'accepts',
            'currency'=>'approves',
            }.each {|from_omrl,link_type| links << create_link(@specification[from_omrl],entity_omrl,link_type)}
        rescue Exception => e
          links.each {|link| link.destroy}
          raise e
        end
        
      end
    end
  end

protected
  ######################################################################################
  # 
  def create_link(from_omrl,to_omrl,link_type,link_specification = nil)
    link_params = {:link_type => link_type,:omrl => to_omrl}
    link_params[:specification] = link_specification if link_specification
    omrl = OMRL.new(from_omrl)
    from_entity = omrl.local?
    if (from_entity) 
      link = Link.new(link_params)
      unless from_entity.links << link
        raise "couldn't create the link! #{link.errors.full_messages.join(',')}"
      end
      link
    else
      raise "#{omrl.url} not local"
      Post.new(omrl.url << '/links',link_params)
    end
  end

end

