######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

# OMRL = open money resource locator.
# an omrl can be one of two things: 
#   - a context based locator like zippy^cc.ny.us or bucks~vegetarians.us or a transaction like zippy#32^cc.ny.us
#   - a transport url like: http://openmoney.info/entities/1 (or a relative one like this: /entities/1)

# This class models an OMRL, and provides resolution of context locators to URLs locators as well as reverse
# resolution for URLs to context locators.

class OMRL
  
  SEPARATOR_FLOW = '/'
  
  attr_reader :flow_id, :parsed, :names

  def to_s
    parse
    omrl = @names.join('.')
    omrl << '/' << @flow_id if flow?
    omrl
  end

  ######################################################################################
  # convenience constructors for the various kinds of omrls
  def OMRL.new_flow(declarer, flow_id)
    OMRL.new("#{declarer}#{SEPARATOR_FLOW}#{flow_id}")
  end


  ######################################################################################
  def initialize(o = nil, context = nil)
  
    omrl = case o
    when String
      o.clone.downcase
    when nil
      ''
    else
      o.to_s.downcase
    end
    
    omrl = "#{omrl}.#{context}" if context && context != ''
    @omrl = omrl
    @url = nil
    @name = nil
    @names = nil
    @parsed = nil
    @flow_id = nil
  end
  
  ######################################################################################
  def omrl=(o)
    #if we set the omrl we have to clear the cached values
    initialze(o)
  end
    
  ######################################################################################
  # returns the entity, i.e. the part before the separator
  def entity_name
    parse
    return @names.first
  end

  ######################################################################################
  # returns the parent_context, i.e. all but the last name
  def parent_context
    parse
    return @names.last(@names.length-1).join('.') if !@names.empty?
    nil
  end
  
  ######################################################################################
  #is this a flow omrl?
  def flow?
    parse
    @flow_id
  end
  
  def flow_declarer
    parse
    @names.join('.')
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
  ######################################################################################
  # private routines that do all the work
  private

  ######################################################################################
  #resolves the omrl down to a url 
  # TODO make this work for non-local omrls!  Right now this just assumes everything is local
  def resolve_to_url
    #special case for the null root omrl
    if @omrl == ''
      return "/entities/1"
    end

    if flow?
#        #confirm that we can find the a link that actually declares the flow
#        return nil if !Link.find_declaring_entity(to_s)
      return "/entities/#{@flow_id}"
    end

    l = Link.find_naming_link(entity_name,parent_context)
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
  
  ######################################################################################
  # parses the omrl
  def parse
    return if @parsed != nil
    @parsed = true
    @names = @omrl.split(/\./)
    if @names.last =~ /(.*)#{SEPARATOR_FLOW}(.*)/
      @names[-1] = $1
      @flow_id = $2
    end
  end

end
