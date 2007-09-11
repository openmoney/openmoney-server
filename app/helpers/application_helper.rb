# Methods added to this helper will be available to all templates in the application.
class Currency
  def self.find(*args)
    Entity.with_scope(:find => { :conditions => "entity_type = 'currency'" }) do
      Entity.find(*args) 
    end
  end
end

class Account
  def self.find(*params)
    Entity.with_scope(:find => { :conditions => "entity_type = 'account'" }) do
      Entity.find(params)
    end
  end
end

class Context
  def self.find(*params)
    Entity.with_scope(:find => { :conditions => "entity_type = 'context'" }) do
      Entity.find(params)
    end
  end
end

class Flow
  
  #TODO this is really not efficient because it means that each time we are searching
  # for flows we are scanning all of them.  
  def self.filter(entities,params)
    if params[:in_currency]
      currency_omrl = OMRL.new(params[:in_currency]).to_s
      entities = entities.collect {|e| c = OMRL.new(e.specification_attribute('currency')).to_s ; (c == currency_omrl) ? e : nil }.reject {|e| e == nil}
    end
    if params[:with]
      account_omrl = OMRL.new(params[:with]).to_s
      
      entities = entities.collect {|e| a = OMRL.new(e.specification_attribute('accepting_account')).to_s ; d = OMRL.new(e.specification_attribute('declaring_account')).to_s ; ((a == account_omrl) || (d == account_omrl)) ? e : nil }.reject {|e| e == nil}
    end
    entities
  end

  def self.find(f, params)
    entities = Entity.find(f, { :conditions => "entity_type = 'flow'" })
    Flow.filter(entities,params)
  end
end


module ApplicationHelper
  
  
end
