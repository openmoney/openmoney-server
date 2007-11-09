######################################################################################
# Copyright (C) 2007 Eric Harris-Braun (eric -at- harris-braun.com), et al
# This software is distributed according to the license at 
# http://openmoney.info/licenses/rubyom
######################################################################################

class SummaryEntry < ActiveRecord::Base
  belongs_to :summary, :polymorphic => true
end

module Summary  
  def updated_at
    self.summary_entry.updated_at
  end
  def self.update_summaries(klass,field,flow)
    result = {}
    begin
      SummaryEntry.transaction do
        result[flow[:declaring_account]] = update_summary(klass,field,flow,flow[:declaring_account],:declaring_account)
        result[flow[:accepting_account]] = update_summary(klass,field,flow,flow[:accepting_account],:accepting_account)
        update_summary(klass,field,flow,flow[:currency],nil)
        update_summary(klass,field,flow,OMRL.new(flow[:declaring_account]).context,:declaring_account)
        update_summary(klass,field,flow,OMRL.new(flow[:accepting_account]).context,:accepting_account)
      end
    rescue Exception => e
      raise e
    end
    result
  end
  
  def self.update_summary(klass,field,flow,entity_omrl,account)
    currency = flow[:currency]
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?',entity_omrl,currency])
    if s.nil?
      s = SummaryEntry.new(:entity_omrl => entity_omrl,:currency_omrl=> currency)
      b = klass.constantize.create(flow,field,account)
      s.summary = b
      s.save!
    else
      b = s.summary
      b.apply(flow,field,account)
      b.save!
      s.updated_at = Time.now
      s.save! #to update the timestamp
    end
    result = b.attributes
    result.delete('id')
    result
  end
end

class Balance < ActiveRecord::Base
  has_one :summary_entry, :as => :summary
  include Summary
  
  def self.create(flow,field,account)
    balance = self.new({:balance => 0,:count =>0, :volume => 0})
    balance.apply(flow,field,account)
    balance
  end
  
  def apply(flow,field,account)
    value = flow[field].to_f
    self.balance = self.balance + value * (account == :declaring_account ? -1 : 1) if account
    self.count = self.count + 1
    self.volume = self.volume + value
    self
  end
end

class Average < ActiveRecord::Base
  has_one :summary_entry, :as => :summary
  include Summary

  def self.create(flow,field,account)
    average = self.new({:average_declared => nil, :average_accepted => nil, :count_declared => 0, :count_accepted => 0})
    average.apply(flow,field,account)
    average
  end
  
  def apply(flow,field,account)
    value = flow[field].to_f
    direction = (account == :declaring_account) ? 'declared' : 'accepted'
    count_key = "count_#{direction}"
    self[count_key] ||= 0
    average_key = "average_#{direction}"
    self[average_key] ||= 0
    old_count = self[count_key]
    new_count = old_count + 1
    self[average_key] = (self[average_key] * old_count  + value)/new_count
    self[count_key] = new_count
    self
  end
end
