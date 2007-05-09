require File.dirname(__FILE__) + '/../spec_helper'

context "parsing an omrl" do
  specify "should report CURRENCY for currency omrls" do
    omrl = OMRL.new('bucks~us')
    omrl.kind.should == OMRL::CURRENCY
    omrl.should be_currency
    omrl.should_not be_account
    omrl.should_not be_flow
  end

  specify "should report ACCOUNT for account omrls" do
    omrl = OMRL.new('zippy^us')
    omrl.kind.should == OMRL::ACCOUNT
    omrl.should be_account
    omrl.should_not be_currency
    omrl.should_not be_flow
  end

  specify "should report FLOW for absolute account omrls" do
    omrl = OMRL.new('bucks#22~us')
    omrl.kind.should == OMRL::FLOW
    omrl.should be_flow
    omrl.should_not be_currency
    omrl.should_not be_account
  end
    
  specify "should report FLOW for absolute currency omrls" do
    omrl = OMRL.new('zippy#22^us')
    omrl.kind.should == OMRL::FLOW
    omrl.should be_flow
    omrl.should_not be_currency
    omrl.should_not be_account
  end

  specify "should report FLOW for relative omrls" do
    omrl = OMRL.new('zippy#22')
    omrl.kind.should == OMRL::FLOW
    omrl.should be_flow
    omrl.should_not be_currency
    omrl.should_not be_account
  end

  specify "should report relative for relative omrls" do
    omrl = OMRL.new('zippy#22')
    omrl.should be_relative
  end

  specify "should parse entity_name for relative omrls" do
    omrl = OMRL.new('zippy')
    omrl.entity_name.should == 'zippy'
  end
  
  specify "should parse entity_name for relative flow omrls" do
    omrl = OMRL.new('zippy#22')
    omrl.entity_name.should == 'zippy#22'
  end
  
  specify "should parse entity_name for absolute flow omrls" do
    omrl = OMRL.new('zippy#22^us')
    omrl.entity_name.should == 'zippy#22'
  end

  specify "should parse entity_name for absolute account omrls" do
    omrl = OMRL.new('zippy^us')
    omrl.entity_name.should == 'zippy'
  end

  specify "should parse entity_name for absolute currency omrls" do
    omrl = OMRL.new('bucks~us')
    omrl.entity_name.should == 'bucks'
  end

  specify "should parse context for absolute currency omrls" do
    omrl = OMRL.new('bucks~us')
    omrl.context.should == 'us'
  end

  specify "should parse context for absolute account omrls" do
    omrl = OMRL.new('zippy^us')
    omrl.context.should == 'us'
  end
end


context "A local omrl" do
  fixtures :entities
  specify "should report local?" do
    omrl = OMRL.new(1)
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

