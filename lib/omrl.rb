######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

# OMRL = open money resource locator.
# an omrl can be any of three things: 
#   1- an open money name like zippy^cc.ny.us or bucks~vegetarians.us or a transaction like zippy#32^cc.ny.us
#   2- an open money number like 1^2233.12.1 or 76~3334321.1 or a transaction like 1#32^2233.12.1
#   3- a transport url like: http://openmoney.info/entities/1 (or a relative one like this: /entities/1)
# additionally omrls can be absolute or relative.  i.e. a relative open money number is just a number (i.e. an id)
# and a relative openmoney name is just text.  The context will then be figured out according to the situation.

# This class models an OMRL, and provides downward resolution of Names to Numbers and URLs as well as upward
# resolution for nums and URLs to names.

class OMRL
  
  OM_NUM = :num
  OM_NAME = :name
  OM_URL = :url
  
  CURRENCY = :currency
  FLOW = :flow
  ACCOUNT = :account
  CONTEXT = :context
  
  SEPARATOR_CURRENCY = '~'
  SEPARATOR_ACCOUNT = '^'
  SEPARATOR_FLOW = '#'
  SEPARATOR_CONTEXT = '.'

  attr_reader :flow_declarer, :flow_id, :separator, :parsed

  def to_s
    @omrl
  end

  def OMRL.new_flow(declarer, flow_id)
    o = OMRL.new(declarer)
    t = "#{o.entity}#{SEPARATOR_FLOW}#{flow_id}#{o.separator}"
    t << o.context if !o.relative?
    OMRL.new(t)
  end

  def OMRL.new_context(name, parent_context)
    t = "#{name}#{SEPARATOR_CONTEXT}#{parent_context}"
    OMRL.new(t)
  end

  def OMRL.new_account(name, parent_context)
    t = "#{name}#{SEPARATOR_ACCOUNT}#{parent_context}"
    OMRL.new(t)
  end
  
  def OMRL.new_currency(name, parent_context)
    t = "#{name}#{SEPARATOR_CURRENCY}#{parent_context}"
    OMRL.new(t)
  end
  

  ######################################################################################
  def initialize(o = '')
    @omrl = o.clone.to_s  #since a plain number is a valid omrl we always covert all input to a string
    @type = nil
    @kind = nil
    @url = nil
    @num = nil
    @name = nil
    @local = nil
    @relative = nil
    @name_entity = nil
    @name_context = nil
    @num_entity = nil
    @num_context = nil
    @parsed = nil
    @flow_declarer = nil
    @flow_id = nil
    @separator = nil
  end
  
  ######################################################################################
  def omrl=(o)
    #if we set the omrl we have to clear the cached values
    initialze(o)
  end
  
  ######################################################################################
  #returns whether this is a relative url
  def relative?
    parse
    @relative
  end
  
  ######################################################################################
  # returns the entity, i.e. the part before the separator
  def entity
    parse
    return @name_entity if om_name?
    return @num_entity if om_num?
  end

  ######################################################################################
  #returns the context, i.e. the part after the separator
  def context
    parse
    return @name_context if om_name?
    return @num_context if om_num?
  end
  
  ######################################################################################
  #returns the nth sub-context where 0 is the left-most context
  # because entity ids are unique in this implementation, this is an easy way to find
  # the entity id of an OM_NUM omrl context
  def context_leaf(position = 0)
    raise "Cannot report context on a relative OMRL #{@omrl}" if relative?
    c = context
    c.split(/\./)[position]
  end
  
  ######################################################################################
  #returns the kind of OMRL as one of the constants CURRENCY FLOW ACCOUNT
  def kind
    parse
    @kind
  end
  
  def currency?
    parse
    kind == CURRENCY
  end

  def account?
    parse
    kind == ACCOUNT
  end

  def flow?
    parse
    kind == FLOW
  end

  def context?
    parse
    kind == CONTEXT
  end
  
  ######################################################################################
  #returns the type as one of the constants OM_NUM, OM_URL or OM_NAME
  def type
    return @type if @type != nil #return cached value
    @type = case @omrl
    when /^[0-9][0-9.]*[0-9]*/
      OM_NUM
    when /^(\w+:)|\//
      OM_URL
    else
      OM_NAME
    end
  end
  
  def om_num?
    type == OM_NUM
  end

  def om_name?
    type == OM_NAME
  end

  def om_url?
    type == OM_URL
  end

  ######################################################################################
  ######################################################################################
  # resolution routines
  ######################################################################################

  #does this omrl exist on this server?
  # TODO: for now this is a cheat because it just looks to see if the context names match up
  # with the link pattern.  Later this needs to be true name resolution
  def local?
    return @local if @local != nil

    raise "haven't implemented local? for OM_URLs!" if om_url?

    parse

    if om_num?
      case @kind
      when CONTEXT
        entity_id = context_leaf
      when FLOW
        entity_id = flow_id
      else
        entity_id = entity
      end
    else
      if relative?
        entity_name = flow? ? @flow_declarer : @name_entity
        l = Link.find_naming_link(entity_name)
        if l
          raise "Can't disambiguate relative omrl:  There is more than one entity with the name #{entity_name}" if l.is_a?(Array)
          entity_id = @num_entity = get_entity_id_from_link(l)
        end
      else
        context_ids = Link.find_context_entity_ids(context)
        if context_ids
          @num_context = context_ids.join('.')
          if context?
            entity_id = context_ids[0]
          else
            l = Link.find_naming_link(flow? ? @flow_declarer : @name_entity,context_ids[0])
            if l
              entity_id = @num_entity = get_entity_id_from_link(l)
            end
          end
        end
      end
    end
    
    @local = false
    if entity_id
      begin
        # this only works because all entities have unique ids!
        @local = Entity.find(entity_id)
      rescue ActiveRecord::RecordNotFound
        #local was set to false above, no need to do it here
      end
    end
    
    @local
  end
  
  def get_entity_id_from_link(link)
    o = OMRL.new(link.omrl)
    raise "WOHA! A naming link omrl must be a OM_NUM omrl (was #{link.omrl})" if !o.om_num?
    if flow?
      # we've proven that the declarer exists locally so the entity id for the flow
      # should just be the id from this omrl
      flow_id
    else
      #otherwise the entity id should be the entity section of the link omrl
      o.entity
    end
  end
  
  ######################################################################################
  #  return the URL for this omrl by resolving it
  def url
    return @url if @url != nil #return cached value
    @url = resolve_to_url
  end

  ######################################################################################
  #  return the num for this omrl by resolving it
  def num
    return @num if @num != nil #return cached value
    case type
    when OM_URL
      #TODO: is this right?  The num is just the id at the right hand of the URL?  
      if @omrl =~/([0-9]+)$/
        @num = $1
      else
        raise "unable to convert a URL omrl to an OM_NUM [for omrl #{@omrl}]"
      end
    when OM_NUM
      @num = @omrl
    when OM_NAME
      @num = resolve_name_to_num
    end
  end
  
  ######################################################################################
  def name
    return @name if @name != nil #return cached value
    case type
    when OM_URL, OM_NUM
      @name = Entity.find_by_omrl(num).omrl
    when OM_NAME
      @name = @omrl
    end
  end

  ######################################################################################
  ######################################################################################
  # private routines that do all the work
  private
  
  ######################################################################################
  # parses the omrl
  def parse
    return if @parsed != nil
    @parsed = true
    return if om_url?

    if @omrl =~ /^(.*)([#{SEPARATOR_CURRENCY}#{SEPARATOR_ACCOUNT}])(.*)$/
      entity = $1
      @separator = $2

      @relative = $3 == ""
      context = $3 if !@relative

      if entity =~ /(.*)#{SEPARATOR_FLOW}(.*)/
        raise "currencies can't be flow declarers #{entity}" if @separator == SEPARATOR_CURRENCY
        @flow_declarer = $1
        @flow_id = $2
        @kind = FLOW
      else
        @kind = case @separator
        when SEPARATOR_ACCOUNT
          ACCOUNT
        when SEPARATOR_CURRENCY
          CURRENCY
        end
      end
    else
      if @omrl =~ /\./
        context = @omrl
        @kind = CONTEXT
        @relative = false
      else
        @relative = true
        entity = @omrl
        if entity =~ /(.*)#{SEPARATOR_FLOW}(.*)/
          @kind = FLOW
          @flow_declarer = $1
          @flow_id = $2
        end
      end
    end

    context.gsub!(/\.$/,'') if context
    case type
    when OM_NAME
      @name_entity = entity
      @name_context = context
    when OM_NUM
      @num_entity = entity
      @num_context = context
    end
    
    @kind
  end
  
  
  ######################################################################################
  #resolves the omrl down to a url 
  def resolve_to_url
    case type
    when OM_URL
      @omrl
    when OM_NUM
      resolve_num_to_url
    when OM_NAME
      resolve_name_to_num
      resolve_num_to_url
    end
  end
  
  ######################################################################################
  def resolve_num_to_url
    parse
    if local?
      if flow?
        return "/entities/#{@flow_id}"
      else
        return "/entities/#{@num_entity}"
      end
    end
    raise "resolve_num_to_url not implemented for external om nums! [omrl #{@omrl} = num #{@num_entity}]"
  end
  
  ######################################################################################
  def resolve_name_to_num
    raise "WHOA! this OMRL isn't an OM_NAME" if type != OM_NAME

    #special case for the null root omrl
    if @omrl == ''
      return "1"
    end

    if local?
      relative? ? @num_entity : "#{@num_entity}#{@separator}#{@num_context}"
    else
      raise "resolve_name_to_num not implemented for non local omrl #{@omrl} name=#{@name_entity}"
    end
  end
end
