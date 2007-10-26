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
      err = "link not allowed: #{typed_entity.link_error}"
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

  def url_omrl(relative = true)
    if local?
      "/entities/#{id}"
    else
      raise "non-local entities not yet implmented"
    end
  end
  
  def omrl_name(relative = false)
    
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
    context = relative ? nil : (names.join('.') << '.')
    case entity_type
    when "context"
      OMRL.new_context(name,context).to_s
    when "currency"
      OMRL.new_currency(name,context).to_s
    when "account"
      OMRL.new_account(name,context).to_s
    end
  end
  
  #TODO this allways returns a relative OMRL!
  def omrl(relative = false,type = OMRL::OM_NAME)
    if type == OMRL::OM_NAME
      omrl_name(relative)
    else
      url_omrl(relative)
    end
  end
  
  #confirm access to this entity via the access control configuration
  def valid_credentials(credentials)
    pass = credentials[:password]
    return true if access_control.nil?
    if ac = YAML.load(access_control)
      mkpasswd(pass,ac['salt']) == ac['password_hash']
    else
      true
    end
  end
  
  def set_password(password)
    salt = mksalt
    ac = {'salt' => salt,'password_hash'=>mkpasswd(password,salt)}
    self.access_control = ac.to_yaml
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
      true
    end
  end
  
  ######################################################################################
  class Account < Entity
    def allow_link?(link)
      return false if not link_type_err_check({"declares"=>"flow","accepts"=>"flow"},link)
      if link.link_type == "declares"
        ack_password = link.specification_attribute('ack_password')
        raise "incorrect acknowledgment password" if !valid_credentials(:password=>ack_password)
        link.delete_specification_attribute('ack_password')
      end
      true
    end
    
  end

  ######################################################################################
  class Currency < Entity
    def allow_link?(link)
      return false if not link_type_err_check({"approves"=>"flow", "is_used_by"=>"account","originates_from"=>"account"},link)

      if link.link_type == "approves"
        flow = link.specification_attribute('flow')
        s = specification_attribute('summaries')
        s ||= {}
        if specification_attribute('summary_type') =~ /^(.+)\((.+)\)$/
          summary_type,summary_field = $1,$2
        else
          summary_type,summary_field = 'balance','amount'
        end
        
        sf = flow[summary_field]
        flow_amount = sf.to_i
        raise "field to summarize (#{summary_field}) not found!" if !sf

        s['count'] =  s['count'].to_i + 1
        s['volume'] =  s['volume'].to_i + flow_amount.abs

        declarer_omrl = flow['declaring_account']
        accepter_omrl = flow['accepting_account']
        case summary_type 
        when "balance"
          s[declarer_omrl] = update_balance(s[declarer_omrl],-flow_amount)
          s[accepter_omrl] = update_balance(s[accepter_omrl],flow_amount)
        when "mean"
          s[declarer_omrl] = update_mean(s[declarer_omrl],flow_amount,'declared')
          s[accepter_omrl] = update_mean(s[accepter_omrl],flow_amount,'accepted')
        else
          raise "unknown summary type: #{summary_type}"
        end
#        link.set_specification_attribute('summary',s)
        set_specification_attribute('summaries',s)
        return {'summary' => {declarer_omrl => s[declarer_omrl], accepter_omrl => s[accepter_omrl]}}
      end
      
      true
    end
    
    private 
    def update_balance(summary,amount)
      summary ||= {}
      summary['count'] ||= 0
      summary['volume'] ||= 0
      summary['balance'] ||= 0
      summary['balance'] = summary['balance'] + amount
      summary['volume'] = summary['volume'] + amount.abs
      summary['count'] = summary['count'] + 1
      summary
    end
    def update_mean(summary,amount,direction)
      summary ||= {}
      count = "count_#{direction}"
      summary[count] ||= 0
      mean = "mean_#{direction}"
      summary[mean] ||= 0
      old_count = summary[count]
      new_count = old_count + 1
      summary[mean] = (summary[mean] * old_count  + amount)/new_count
      summary[count] = new_count
      summary
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
