######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

class Link < ActiveRecord::Base
  include Specification

  Types = %w(names approves accepts declares is_used_by)

  belongs_to :entity
  validates_inclusion_of :link_type, :in => Types
  validates_presence_of :omrl
  validates_presence_of :entity_id

  def initialize(params)
    super(params)
  end
  
  def omrl=(omrl_string)
    o = OMRL.new(omrl_string)
    # this makes sure that the omrl is converted to canonical form 
    write_attribute(:omrl, o.to_s)
  end
    
  ######################################################################################
  def validate_on_create
    case link_type
    when 'names'
      validate_specification({'name' => :required})
      if @specification
        n = @specification['name']
        if Link.find_naming_link(n,entity_id)
          errors.add(:specification,"name '#{n}' already exists")
        end
      end
    end
    false
  end

  def omrl_url
    o = OMRL.new(omrl)
    o.url
  end
  
  #TODO make this a real PGP signature
  def add_signature
    set_specification_attribute('signature',"localhost:" << Time.now.to_i.to_s)
  end

  def add_result(result)
    set_specification_attribute('result',result)
  end
    
  ######################################################################################
  # CLASS METHODS
  ######################################################################################

  # class method to return a naming link optionally from a given context
  def Link.find_naming_link(name,context=nil)

    if (context)
      #TODO won't work for non-local entities
      
      if context.is_a?(String)
        e = Entity.find_by_omrl(context)
        return nil if !e
        entity_id = e.id
      elsif context.is_a?(Entity)
        entity_id = context.id
      elsif context.is_a?(Fixnum)
        entity_id = context
      else
        raise "context parameter must be omrl String, and Entity, or an entity_id Fixnum"
      end

      conditions = ["link_type = 'names' and entity_id = ? and specification like ?", entity_id,"%name: #{name}\n%"]
    else
      conditions = ["link_type = 'names' and specification like ?", "%name: #{name}\n%"]
    end
    links = Link.find(:all, :conditions => conditions)
    return nil if links.size == 0
    return links[0] if links.size == 1
    links
  end
 
  ######################################################################################
  def Link.find_declaring_entity(omrl)
    conditions = ["link_type = 'declares' and omrl = ?", omrl]
    link = Link.find(:first, :conditions => conditions)
    link.entity if link
  end
  
  ######################################################################################
  # does a recursive search back through each naming links to get the name and context
  # of a given entity id.
  #TODO this only works for fully local items.  It should actually be able to scan back 
  # accross the net, not just on this server
  def Link.entity_naming_chain(id)
    return [] if id == 1
    conditions = ["link_type = 'names' and omrl = ?", "/entities/#{id}"]
    link = Link.find(:first, :conditions => conditions)
    return nil if !link
    [link.specification_attribute("name")].concat(Link.entity_naming_chain(link.entity_id))
  end
  
end
