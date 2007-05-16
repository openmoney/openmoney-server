require File.dirname(__FILE__) + '/../spec_helper'

context "creating omrls" do
  specify "shoul work for flow omrls" do
    OMRL.new_flow("fish^boink.us",35).to_s.should == "fish#35^boink.us"
  end
  specify "shoul work for context omrls" do
    OMRL.new_context("ca","us").to_s.should == "ca.us"
  end
  specify "shoul work for account omrls" do
    OMRL.new_account("zippy","ny.us").to_s.should == "zippy^ny.us"
  end
  specify "shoul work for currency omrls" do
    OMRL.new_currency('bucks','us').to_s.should == "bucks~us"
  end
end

context "parsing an omrl" do
  specify "should report CURRENCY for currency omrls" do
    omrl = OMRL.new('bucks~us')
    omrl.kind.should == OMRL::CURRENCY
    omrl.should be_currency
    omrl.should_not be_account
    omrl.should_not be_flow
    omrl.should_not be_context
  end

  specify "should report ACCOUNT for account omrls" do
    omrl = OMRL.new('zippy^us')
    omrl.kind.should == OMRL::ACCOUNT
    omrl.should be_account
    omrl.should_not be_currency
    omrl.should_not be_flow
    omrl.should_not be_context
  end
    
  specify "should report FLOW for absolute account omrls" do
    omrl = OMRL.new('zippy#22^us')
    omrl.kind.should == OMRL::FLOW
    omrl.should be_flow
    omrl.should_not be_currency
    omrl.should_not be_account
    omrl.should_not be_context
    omrl.flow_declarer.should == "zippy"
    omrl.flow_id.should == "22"
  end

  specify "should report FLOW for relative omrls" do
    omrl = OMRL.new('zippy#22')
    omrl.kind.should == OMRL::FLOW
    omrl.should be_flow
    omrl.should_not be_currency
    omrl.should_not be_account
    omrl.should_not be_context
    omrl.flow_declarer.should == "zippy"
    omrl.flow_id.should == "22"
  end

  specify "should report CONTEXT for context omrls" do
    omrl = OMRL.new('cc.us')
    omrl.kind.should == OMRL::CONTEXT
    omrl.should be_context
    omrl.should_not be_currency
    omrl.should_not be_account
    omrl.should_not be_flow
    omrl.context.should == 'cc.us'
  end

  specify "should report CONTEXT for top level context omrls" do
    omrl = OMRL.new('us.')
    omrl.should be_context
    omrl.context.should == 'us'
  end

  specify "should report relative for relative omrls" do
    omrl = OMRL.new('zippy#22')
    omrl.should be_relative
  end

  specify "should parse entity_name for relative omrls" do
    omrl = OMRL.new('zippy')
    omrl.entity.should == 'zippy'
  end
  
  specify "should parse entity_name for relative flow omrls" do
    omrl = OMRL.new('zippy#22')
    omrl.entity.should == 'zippy#22'
  end
  
  specify "should parse entity_name for absolute flow omrls" do
    omrl = OMRL.new('zippy#22^us')
    omrl.entity.should == 'zippy#22'
  end

  specify "should parse entity_name for absolute account omrls" do
    omrl = OMRL.new('zippy^us')
    omrl.entity.should == 'zippy'
  end

  specify "should parse entity_name for absolute currency omrls" do
    omrl = OMRL.new('bucks~us')
    omrl.entity.should == 'bucks'
  end

  specify "should parse context for absolute currency omrls" do
    omrl = OMRL.new('bucks~us')
    omrl.context.should == 'us'
  end

  specify "should parse context for absolute account omrls" do
    omrl = OMRL.new('zippy^us')
    omrl.context.should == 'us'
  end

  specify "should parse leaves properly" do
    omrl = OMRL.new('fred^cc.us')
    omrl.context_leaf.should == 'cc'
    omrl.context_leaf(1).should == 'us'
    omrl = OMRL.new('zippy^us')
    omrl.context_leaf.should == 'us'
  end
end


context "Local omrls" do
  fixtures :entities
  fixtures :links

  specify "root should report local?" do
    omrl = OMRL.new('1')
    omrl.should_be_local
  end

  specify "relative num account omrls should report local?" do
    omrl = OMRL.new(entities(:account_zippy).id.to_s)
    omrl.should_be_local
  end

  specify "account relative should report local?" do
    omrl = OMRL.new('zippy')
    omrl.should_be_local
  end

  specify "account absolute should report local?" do
    omrl = OMRL.new('zippy^us')
    omrl.should_be_local
  end

  specify "flow relative should report local?" do
    omrl = OMRL.new('zippy#' << entities(:flow_tx1).id.to_s)
    omrl.should_be_local
  end

  specify "flow absolute should report local?" do
    omrl = OMRL.new('zippy#' << entities(:flow_tx1).id.to_s << 'us')
    omrl.should_be_local
  end
  
  specify "currency relative should report local?" do
    omrl = OMRL.new('bucks')
    omrl.should_be_local
  end

  specify "account absolute should report local?" do
    omrl = OMRL.new('bucks~us')
    omrl.should_be_local
  end

  specify "context should report local?" do
    omrl = OMRL.new('us.')
    omrl.should_be_local
  end

end

context "A non local omrl" do
  fixtures :entities
  specify "should fail to report local?" do
    omrl = OMRL.new(66)
    omrl.should_not_be_local
  end
end

context "An OM_NAME omrl" do
  fixtures :entities
  fixtures :links
  setup do
    @omrl = OMRL.new("zippy")
  end
  specify "should be of type OM_NAME" do
    @omrl.type.should == OMRL::OM_NAME
  end
  specify "should convert to a num" do
    @omrl.num.should == entities(:account_zippy).id.to_s
  end
  specify "should convert to a url" do
    @omrl.url.should == "/entities/" << entities(:account_zippy).id.to_s
  end
end

context "An OM_NUM omrl" do
  fixtures :entities
  fixtures :links
  setup do
    @omrl = OMRL.new(5)
  end
  specify "should be of type OM_NUM" do
    @omrl.type.should == OMRL::OM_NUM
  end
  specify "should convert to a num" do
    @omrl.num.should == "5"
  end
  specify "should convert to a name" do
    @omrl.name.should == "zippy"
  end
  specify "should convert to a url" do
    @omrl.url.should == "/entities/5"
  end
end

context "An OM_URL omrl" do
  fixtures :entities
  fixtures :links
  setup do
    @omrl = OMRL.new("/entities/6")
  end
  specify "should be of type OM_URL" do
    @omrl.type.should == OMRL::OM_URL
  end
  specify "should convert to a num" do
    @omrl.num.should == "6"
  end
  specify "should convert to a name" do
    @omrl.name.should == "mwl"
  end
  specify "should convert to a url" do
    @omrl.url.should == "/entities/6"
  end
end

