######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

class Entity < ActiveRecord::Base
  include Specification
  has_many :links, :before_add => :link_allowed

  def link_error
    @link_error
  end

  ######################################################################################
  # this is a factory method that creates Entities of the correct type if they have been
  # subclassed, otherwise it raises an exception
  def self.create(params)
    class_name = "Entity::#{params[:entity_type].capitalize}"
    begin
      class_name.constantize.new(params)
    rescue Exception => e
      raise "Unknown entity type: #{params[:entity_type]} (#{e.to_s})"
    end
  end

  ######################################################################################
  # before adding a link to an entity, we have to let the entity have a crack at 
  # agreeing to the link
  def link_allowed(link)
    typed_entity = Entity.create({:entity_type => entity_type, :specification =>specification})
    if !typed_entity.allow_link?(link) 
      err = "link not allowed: #{typed_entity.link_error}"
      errors.add_to_base(err)
      raise err
    end
    true
  end
  
  ######################################################################################
  # access control should never be visible when converting to xml
  def to_xml(options = {})
     options[:except] ||= []
     options[:except].push(:access_control) 
     super(options)
  end
  
  ######################################################################################
  def validate_on_create
    validate_specification({'name' => :required})
    if @specification
      n = @specification['name']
      if (!n || n == "") 
        errors.add(:specification,"'name:' is required")
      else
        if Entity.find_named_entity(n,entity_type)
          errors.add(:specification,"name '#{n}' already exists")
        end
      end
    end
  end
  
  ######################################################################################
  # return an omrl for this entity
  def omrl(type = OMRL::OM_NAME,relative = true)
    case type
    when OMRL::OM_URL
      "/entities/#{self.id}"
    when OMRL::OM_NUM
      "#{self.id}"
    when OMRL::OM_NAME
      @specification['name']
    end
  end
  
  ######################################################################################
  # returns the name of the entity
  def name
    attribute("name")
  end
  
  def attribute(attrib)
    load_specification
    @specification[attrib]
  end  
  
  ######################################################################################
  # CLASS METHODS
  ######################################################################################
  # class method to return a named entity optionally of a given type
  # NOTE: This may change because the
  # name may be moved to being a column of entity rather than part of the yaml spec block.
  def Entity.find_named_entity(name,entity_type=nil)
    if (entity_type) 
      conditions = ["entity_type = ? and specification like ?", entity_type,"%name: #{name}%"]
    else
      conditions = ["specification like ?", "%name: #{name}%"]
    end
    Entity.find(:first, :conditions => conditions)
  end
  
  ######################################################################################
  # class method to return a the name of a know entity.  NOTE:This may change because the
  # name may be moved to being a column of entity rather than part of the yaml spec block.
  def Entity.get_entity_name(id)
    e = Entity.find(id)
    e.name
  end
  
  ######################################################################################
  # Entity class types
  ######################################################################################
  class Context < Entity
    def allow_link?(link)
      return false if not link_type_err_check(%W(named_in approves managed_by created_by),link)
      true
    end
  end
  
  ######################################################################################
  class Account < Entity
    def allow_link?(link)
      return false if not link_type_err_check(%W(flow_from flow_to),link)
      true
    end
  end

  ######################################################################################
  class Currency < Entity
    def allow_link?(link)
      return false if not link_type_err_check(%W(named_in approves uses managed_by created_by),link)
      true
    end
  end

  ######################################################################################
  class Flow < Entity
    #flows aren't linked to anything, things are linked to flows
    def allow_link?(link)
      false 
    end
  end

  ######################################################################################
  protected
  def link_type_err_check(valid_type_list,link)
    if not valid_type_list.include?(link.link_type)
      @link_error = "improper link type: #{link.link_type}"
      return false
    end
    return true
  end
end

