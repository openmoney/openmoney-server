######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################
class Entity < ActiveRecord::Base

  Types = %w(context account currency flow)

  include Specification
  has_many :links, :before_add => :link_allowed
  validates_inclusion_of :entity_type, :in => Types
  attr_protected :access_control

  attr :link_error
#  def link_error
#    @link_error
# end

  ######################################################################################
  # this is a factory method that creates Entities of the correct type if they have been
  # subclassed, otherwise it raises an exception
  def self.create(params)
    class_name = "Entity::#{params[:entity_type].capitalize}"
    begin
      class_name.constantize.new(params)
    rescue NameError => e
#      ent = Entity.new
#      ent.errors.add(:entity_type, e.to_s)
#      ent
      raise "Unknown entity type: #{params[:entity_type]}"
    end
  end

  ######################################################################################
  # before adding a link to an entity, we have to let the entity have a crack at 
  # agreeing to the link
  def link_allowed(link)

    typed_entity = Entity.create({:entity_type => entity_type, :specification =>specification})
    typed_entity.access_control = access_control
    typed_entity.id = id

    result = typed_entity.allow_link?(link) 
    if !result
      err = "#{link.link_type} link not allowed: #{typed_entity.link_error}"
      errors.add_to_base(err)
      raise err
    elsif result && result != true
      #if there is a result other than true, then the entity is giving us
      # some information to be stored in the link
      link.add_result(result)
    end

    link.add_signature()

    #TODO: what if the omrl is not the same type?  Then this will fail.
    if links.find(:first, :conditions => ["omrl = ? and link_type = ?",link.omrl,link.link_type] )
      err = "duplicate link attempt: #{omrl} already #{link.link_type} #{link.omrl}"
      errors.add_to_base(err)
      raise err
    end
    if result && result != true
      # allow for the allow_link? call to have a side-effect on the specification.
      # and if it has changed, updated it.  For now this is how we are implementing
      # saving of the summary during a flow acknowledgement.  Not great but it works.
      if self.specification != typed_entity.specification
        self.specification = typed_entity.specification
        save
      end
    end
    true
  end
  
  def allow_link?(link)
    credentials = link.specification_attribute('credentials')
    credential = credentials[self.omrl] if credentials
    if !valid_credentials(credential,link.link_type)
      logger.info "INVALID CREDENTIAL" << credential.inspect << " for " << link.link_type
      logger.info "CREDENTIALS ARE:" << credentials.inspect
      @link_error = "invalid credential"
      return false
    end 
    link.delete_specification_attribute('credentials')
    true
  end
  
  ######################################################################################
  # access control should never be visible when converting to xml
  # nor should the summaries if this is a currency.  
  # TODO: This is probably an indicator that summaries need to be moved out of the specification
  # and either into their own table, or into their own entity type.
  # TODO: this wipes out any procs you add in!
  def to_xml(options = {})
     options[:except] ||= []
     options[:except].push(:access_control) 
     if entity_type == "currency"
       options[:except].push(:specification) if !options[:except].include?(:specification)
       options[:procs] = [Proc.new { |o|
         spec = get_specification.clone
         if options[:summaries]
           s = spec['summaries']
           s.keys.each { |a| s.delete(a) unless options[:summaries].include?(a)} if s
         else
           spec.delete('summaries')
         end
         o[:builder].tag!('specification', spec.to_yaml,:type => :string)
       }]
     end
     super(options)
  end
  
  ######################################################################################
#  def validate_on_create
#    validate_specification({'name' => :required})
#    if @specification
#      n = @specification['name']
#      if Entity.find_named_entity(n,entity_type)
#        errors.add(:specification,"name '#{n}' already exists")
#      end
#    end
#  end
  
  ######################################################################################
  # return the context for this entity
  # TODO this assumes there is just one context for each entity which may not be true
  def context
    if entity_type == "flow"
      OMRL.new(specification_attribute('declaring_account')).context
    else
      specification_attribute('parent_context')
    end
  end


  ######################################################################################
  # return an omrl for this entity

  def url
    if local?
      "/entities/#{id}"
    else
      raise "non-local entities not yet implmented"
    end
  end
  
  def omrl
    
    #TODO deal with the multiple omrls for the same entitiy
    
    #TODO this should really be moved into the sub-classes of Entity rather than
    # being a big switch statement, but right now when entities are pulled back out of
    # the database they are instantiated as Entities not as Entity::<subclass> which 
    # i still need to figure out how to do.
    if entity_type == "flow"
      return OMRL.new_flow(specification_attribute('declaring_account'),id).to_s
    end

    names = Link.entity_naming_chain(id)
    return nil if !names

    name = names.shift
    context = names.join('.')
    OMRL.new(name,context).to_s
  end
    
  #confirm access to this entity via the access control configuration
  def valid_credentials(credential,authority)
    return true if access_control.nil?
    return true if default_authorities.include?(authority)
    if ac = YAML.load(access_control)
      return false if credential == nil
      ac = ac[credential[:tag]]
      return false if ac.nil?
      pass = credential[:password]
      auths = ac[:authorities]
      mkpasswd(pass,ac[:salt]) == ac[:password_hash] && (auths == '*' || auths.include?(authority))
    else
      true
    end
  end
  
  def set_credential(tag,password,authorities = '*')  # default authority is the wildcard authortiy
    salt = mksalt
    ac = YAML.load(access_control) if access_control
    ac ||= {}
    authorities = '*' if authorities.class == Array && authorities.include?('*')
    ac.update({tag => {:salt => salt,:password_hash=>mkpasswd(password,salt),:authorities => authorities}})
    self.access_control = ac.to_yaml
  end
  
  def set_default_authorities(*authorities)
    set_credential('','',authorities.flatten)
  end
  
  def default_authorities
    auths = []
    if access_control && ac = YAML.load(access_control)
      ac = ac['']
      auths.concat(ac[:authorities]) if ac
    end
    auths
  end
  
  def remove_credential(tag)
    if access_control
      ac = YAML.load(access_control)
      ac.delete(tag)
      self.access_control = ac.to_yaml
    end
  end
    
  ######################################################################################
  # CLASS METHODS
  ######################################################################################

  ######################################################################################
  # class method to find an entity by omrl
  def Entity.find_by_omrl(o)
    #TODO make this work with non-local omrls
    url = OMRL.new(o).url
    url =~ /([0-9]+)$/
    entity_id = $1
    Entity.exists?(entity_id) ? Entity.find(entity_id) : nil
  end
  
  ######################################################################################
  # Entity class types
  ######################################################################################
  class Context < Entity
    def allow_link?(link)
      return false if not link_type_err_check({"approves"=>"flow", "names"=>["account","context","currency"]},link)
      return super
    end
  end
  
  ######################################################################################
  class Account < Entity
    def allow_link?(link)
      return false if not link_type_err_check({"declares"=>"flow","accepts"=>"flow"},link)
      return super
    end
    
  end

  ######################################################################################
  require 'app/models/summary_entry'
  class Currency < Entity
    def allow_link?(link)
      return false if not link_type_err_check({"approves"=>"flow", "is_used_by"=>"account"},link)
      return false if !super
      if link.link_type == "approves"
        flow = link.specification_attribute('flow')
        if specification_attribute('summary_type') =~ /^(.+)\((.+)\)$/
          summary_type,summary_field = $1,$2
        else
          summary_type,summary_field = 'balance','amount'
        end

        case summary_type 
        when "balance"
          return {'summary' => Summary.update_summaries('Balance',summary_field,flow)}
        when "average"
          return {'summary' => Summary.update_summaries('Average',summary_field,flow)}
        end
      end
      
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
  ######################################################################################
  protected
    
  ######################################################################################
  def local?
    return true
  end
  
  ######################################################################################
  def link_type_err_check(valid_type_map,link)
    if not valid_type_map.include?(link.link_type)
      @link_error = "improper link type (#{link.link_type}) for #{entity_type}"
      return false
    else
      valid_link_to_entity_types = valid_type_map[link.link_type]
      if valid_link_to_entity_types.class != Array
        valid_link_to_entity_types = [valid_link_to_entity_types]
      end
      e = Entity.find_by_omrl(link.omrl)
      if !e 
        @link_error = "unable to find omrl #{link.omrl} to link to it!"
        return false
      end
      if not valid_link_to_entity_types.include?(e.entity_type)
        @link_error = "#{link.link_type} link can not made to a #{e.entity_type} (omrl=#{e.omrl})"
        return false
      end
    end
    return true
  end

  ################################################################################
  ################################################################################

  private
  require 'digest/sha2'
  
  ################################################################################
  # Make a SHA256 and salt encoded password
  def mkpasswd (plain, salt)
    plain = '' if !plain
    Digest::SHA256.hexdigest(plain + salt)
  end

  ################################################################################
  # Create a salt string
  def mksalt
    [Array.new(6) {rand(256).chr}.join].pack('m').chomp
  end

end
