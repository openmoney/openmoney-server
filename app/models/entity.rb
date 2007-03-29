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
        if Entity.find(:first, :conditions => ["entity_type = ? and specification like ?", entity_type,"%name: #{n}%"])
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
end
