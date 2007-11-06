class SummaryEntry < ActiveRecord::Base
  belongs_to :summary, :polymorphic => true
end

class Balance < ActiveRecord::Base
  has_one :summary_entry, :as => :summary
  def self.update_summaries(field,flow)
    result = {}
    begin
      SummaryEntry.transaction do
        result[flow[:declaring_account]] = update_summary(field,flow,flow[:declaring_account],:declaring_account)
        result[flow[:accepting_account]] = update_summary(field,flow,flow[:accepting_account],:accepting_account)
        update_summary(field,flow,flow[:currency],nil)
        update_summary(field,flow,OMRL.new(flow[:declaring_account]).context,:declaring_account)
        update_summary(field,flow,OMRL.new(flow[:accepting_account]).context,:accepting_account)
      end
    rescue Exception => e
      raise e
    end
    result
  end
  
  def self.update_summary(field,flow,entity_omrl,account)
    currency = flow[:currency]
    s = SummaryEntry.find(:first,:conditions => ['entity_omrl = ? and currency_omrl = ?',entity_omrl,currency])
    if s.nil?
      s = SummaryEntry.new(:entity_omrl => entity_omrl,:currency_omrl=> currency)
      b = Balance.create(flow,field,account)
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
  
  def updated_at
    self.summary_entry.updated_at
  end
end

class Average < ActiveRecord::Base
end
