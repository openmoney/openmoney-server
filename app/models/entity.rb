######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

class Entity < ActiveRecord::Base
  has_many :links
  include Specification
  # access control should never be visible when converting to xml
  def to_xml(options = {})
     options[:except] ||= []
     options[:except].push(:access_control) 
     super(options)
  end
  
  def validate_on_create
    validate_specification({'name' => :required})
    if @specification
      n = @specification['name']
      if (!n || n == "") 
        errors.add(:specification,"'name:' is required")
      else
        if find_named_entity(n,entity_type)
          errors.add(:specification,"name '#{n}' already exists")
        end
      end
    end
  end
  
  def omrl(type = OMRL::OM_NUM,relative = true)
    case type
    when OMRL::OM_URL
      "/entities/#{self.id}"
    when OMRL::OM_NUM
      "#{self.id}"
    when OMRL::OM_NAME
      @specification['name']
    end
  end
  private

  def Entity.find_named_entity(name,entity_type=nil)
    if (entity_type) 
      conditions = ["entity_type = ? and specification like ?", entity_type,"%name: #{name}%"]
    else
      conditions = ["specification like ?", "%name: #{name}%"]
    end
    Entity.find(:first, :conditions => conditions)
  end
end

