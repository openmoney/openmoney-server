require File.dirname(__FILE__) + '/../spec_helper'

describe "creating omrls" do
  it "should work for flow omrls" do
    OMRL.new_flow("fish^boink.us",35).to_s.should == "fish#35^boink.us."
  end
  it "should work for context omrls" do
    OMRL.new_context("ca","us").to_s.should == "ca.us."
  end
  it "should work for account omrls" do
    OMRL.new_account("zippy","ny.us").to_s.should == "zippy^ny.us."
  end
  it "should work for currency omrls" do
    OMRL.new_currency('bucks','us').to_s.should == "bucks~us."
  end
end

describe "parsing an omrl" do
  it "should report CURRENCY for currency omrls" do
    omrl = OMRL.new('bucks~us')
    omrl.kind.should == OMRL::CURRENCY
    omrl.should be_currency
    omrl.should_not be_account
    omrl.should_not be_flow
    omrl.should_not be_context
  end

  it "should report ACCOUNT for account omrls" do
    omrl = OMRL.new('zippy^us')
    omrl.kind.should == OMRL::ACCOUNT
    omrl.should be_account
    omrl.should_not be_currency
    omrl.should_not be_flow
    omrl.should_not be_context
  end
    
  it "should report FLOW for absolute flow omrls" do
    omrl = OMRL.new('zippy#22^us')
    omrl.kind.should == OMRL::FLOW
    omrl.should be_flow
    omrl.should_not be_currency
    omrl.should_not be_account
    omrl.should_not be_context
    omrl.flow_declarer.should == "zippy"
    omrl.flow_id.should == "22"
  end

  it "should report FLOW for relative omrls" do
    omrl = OMRL.new('zippy#22')
    omrl.kind.should == OMRL::FLOW
    omrl.should be_flow
    omrl.should_not be_currency
    omrl.should_not be_account
    omrl.should_not be_context
    omrl.flow_declarer.should == "zippy"
    omrl.flow_id.should == "22"
  end

  it "should report CONTEXT for context omrls" do
    omrl = OMRL.new('cc.us')
    omrl.kind.should == OMRL::CONTEXT
    omrl.should be_context
    omrl.should_not be_currency
    omrl.should_not be_account
    omrl.should_not be_flow
    omrl.context.should == 'cc.us.'
  end

  it "should report CONTEXT for top level context omrls" do
    omrl = OMRL.new('us.')
    omrl.should be_context
    omrl.context.should == 'us.'
  end

  it "should report relative for relative omrls" do
    omrl = OMRL.new('zippy#22')
    omrl.should be_relative
  end

  it "should parse entity_name for relative account omrls" do
    omrl = OMRL.new('zippy^')
    omrl.entity.should == 'zippy'
  end

  it "should parse entity_name for relative currency omrls" do
    omrl = OMRL.new('bucks~')
    omrl.entity.should == 'bucks'
  end

  it "should fail to parse an insufficiently sepecified omrl" do
    OMRL.new('bucks').should raise_error
  end
  
  it "should parse entity_name for relative flow omrls" do
    omrl = OMRL.new('zippy#22')
    omrl.entity.should == 'zippy#22'
  end
  
  it "should parse entity_name for absolute flow omrls" do
    omrl = OMRL.new('zippy#22^us')
    omrl.entity.should == 'zippy#22'
  end

  it "should parse entity_name for absolute account omrls" do
    omrl = OMRL.new('zippy^us')
    omrl.entity.should == 'zippy'
  end

  it "should parse entity_name for absolute currency omrls" do
    omrl = OMRL.new('bucks~us')
    omrl.entity.should == 'bucks'
  end

  it "should parse context for absolute currency omrls" do
    omrl = OMRL.new('bucks~us')
    omrl.context.should == 'us.'
  end

  it "should parse context for absolute account omrls" do
    omrl = OMRL.new('zippy^us')
    omrl.context.should == 'us.'
  end

  it "should parse leaves properly" do
    omrl = OMRL.new('fred^cc.us')
    omrl.context_leaf.should == 'cc'
    omrl.context_leaf(1).should == 'us'
    omrl = OMRL.new('zippy^us')
    omrl.context_leaf.should == 'us'
  end
end


describe "omrls resolution" do
  fixtures :entities
  fixtures :links

  it "should resolve the root omrl" do
    omrl = OMRL.new('.')
    omrl.url.should == "/entities/1"
  end

  it "should resolve context omrls" do
    omrl = OMRL.new('us.')
    omrl.url.should == "/entities/" << entities(:context_us).id.to_s
  end

  it "should resolve account relative omrls" do
    omrl = OMRL.new('zippy^')
    omrl.url.should == "/entities/"  << entities(:account_zippy).id.to_s
  end

  it "should resolve account absolute omrls" do
    omrl = OMRL.new('zippy^us')
    omrl.url.should == "/entities/" << entities(:account_zippy).id.to_s
  end

  it "should resolve flow relative omrls" do
    omrl = OMRL.new('zippy#' << entities(:flow_tx1).id.to_s)
    omrl.url.should == "/entities/" << entities(:flow_tx1).id.to_s
  end

  it "should resolve flow absolute omrls" do
    omrl = OMRL.new('zippy#' << entities(:flow_tx1).id.to_s << '^us')
    omrl.url.should == "/entities/" << entities(:flow_tx1).id.to_s
  end

  it "should resolve currency relative omrls" do
    omrl = OMRL.new('bucks~')
    omrl.url.should == "/entities/"  << entities(:currency_bucks).id.to_s
  end

  it "should resolve currency absolute omrls" do
    omrl = OMRL.new('bucks~')
    omrl.url.should == "/entities/" << entities(:currency_bucks).id.to_s
  end
  
end

describe "An OM_NAME omrl" do
  fixtures :entities
  fixtures :links
  before(:each) do
    @omrl = OMRL.new("zippy^")
  end
  it "should be of type OM_NAME" do
    @omrl.type.should == OMRL::OM_NAME
  end
  it "should convert to a url" do
    @omrl.url.should == "/entities/" << entities(:account_zippy).id.to_s
  end
end

describe "An OM_URL omrl" do
  fixtures :entities
  fixtures :links
  before(:each) do
    @omrl = OMRL.new("/entities/6")
  end
  it "should be of type OM_URL" do
    @omrl.type.should == OMRL::OM_URL
  end

  it "should convert to a name" do
    @omrl.name.should == "mwl^"
  end
  
  it "should convert to a url" do
    @omrl.url.should == "/entities/6"
  end
end

