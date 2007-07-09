######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

# OMRL = open money resource locator.
# an omrl can be one of two things: 
#   - a context based locator like zippy^cc.ny.us or bucks~vegetarians.us or a transaction like zippy#32^cc.ny.us
#   - a transport url like: http://openmoney.info/entities/1 (or a relative one like this: /entities/1)
# additionally omrls can be absolute or relative.  i.e. a relative omrl could be zippy^ , bucks~ or zippy#32

# This class models an OMRL, and provides resolution of context locators to URLs locators as well as reverse
# resolution for URLs to context locators.

# TODO think through the whole relative omrl concept.  I think perhaps this shouldn't even be implemented here at 
# this level

class OMRL
  
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
    case type
    when OM_URL
      @omrl
    when OM_NAME
      omrl = ""
      omrl << entity << separator if !context?
      omrl << context if !relative?
      omrl
    end
  end

  ######################################################################################
  # convenience constructors for the various kinds of omrls
  def OMRL.new_flow(declarer, flow_id)
    o = OMRL.new(declarer)
    t = "#{o.entity}#{SEPARATOR_FLOW}#{flow_id}#{o.separator}"
    t << o.context if !o.relative?
    OMRL.new(t)
  end

  def OMRL.new_context(name, parent_context)
    parent_context = "" if parent_context == "."
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
    # this clone is here because there was a side-effect that the omrl string object was being
    # modified by some function in OMRL and it was messing things up externally.
    omrl = o.is_a?(Fixnum) ? o.to_s : o.clone
    @omrl = omrl
    @type = nil
    @kind = nil
    @url = nil
    @name = nil
    @entity = nil
    @relative = nil
    @entity_portion = nil
    @context_portion = nil
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
    return @entity_portion if om_name?
    nil
  end

  ######################################################################################
  #returns the context, i.e. the part after the separator
  def context
    parse
    return @context_portion if om_name?
    nil
  end
  
  ######################################################################################
  #returns the nth sub-context where 0 is the left-most context
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
  #returns the type as one of the constants, OM_URL or OM_NAME
  def type
    return @type if @type != nil #return cached value
    @type = case @omrl
    when /^(\w+:)|\//
      OM_URL
    else
      OM_NAME
    end
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

  
  ######################################################################################
  #  return the URL for this omrl by resolving it
  def url
    return @url if @url != nil #return cached value
    @url = resolve_to_url
  end

  ######################################################################################
  def name
    return @name if @name != nil #return cached value
    case type
    when OM_URL
      @name = Entity.find_by_omrl(url).omrl
    when OM_NAME
      @name = @omrl
    end
  end

  ######################################################################################
  ######################################################################################
  # private routines that do all the work
  private

  ######################################################################################
  #resolves the omrl down to a url 
  # TODO make this work for non-local omrls!  Right now this just assumes everything is local
  def resolve_to_url
    case type
    when OM_URL
      @omrl
    when OM_NAME
      #special case for the null root omrl
      if @omrl == '.'
        return "/entities/1"
      end

      if flow?
        #confirm that we can find the a link that actually declares the flow
        return nil if !Link.find_declaring_entity(to_s)
        return "/entities/#{@flow_id}"
      end
          
      if context?
        contexts = context.split(/\./)
        the_name = contexts.shift
        the_context = contexts.join('.')<<'.'
      else
        the_name = @entity_portion
        the_context = context
      end
      l = Link.find_naming_link(the_name,the_context)
 #     raise "could not find naming link for name: #{the_name} in context: #{the_context}" if !l
      if l
        if l.is_a?(Array)
          l[0].omrl
        else
          l.omrl
        end
      else
        nil
      end
    end
  end
  
  ######################################################################################
  # parses the omrl
  def parse
    return if @parsed != nil
    @parsed = true
    return if om_url?

    if @omrl =~ /^(.*)([#{SEPARATOR_CURRENCY}#{SEPARATOR_ACCOUNT}])(.*)$/

      #split the omrl into the three parts, the entity, the separator which and the context
      # if there is no context, then it's a relative omrl
      entity = $1
      @separator = $2
      @relative = $3 == ""
      context = $3 if !@relative

      # to determine the omrl kind the entity section must be even further parsed because a flow entity consists of the declarer
      # and the flow id.
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
      # if there is no currency or account separator then we assume that the omrl is a context omrl if there
      # are any periods in the text.  Other wise we assume that it is a relative, and we can figure out if it is
      # a flow by looking for a flow id separator
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
        else
          raise "omrl '#{@omrl}' insufficiently specified.  It could be either an account a currency, or a context."
        end
      end
    end

    context << '.' if context =~ /[^.]$/
    case type
    when OM_NAME
      @entity_portion = entity
      @context_portion = context
    end
    
    @kind
  end

end
