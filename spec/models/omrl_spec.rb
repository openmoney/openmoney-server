require File.dirname(__FILE__) + '/../spec_helper'

describe "creating omrls" do
  it "should work create a flow omrl" do
    omrl = OMRL.new_flow("us.boink.fish",35)
    omrl.to_s.should == "us.boink.fish/35"
    omrl.should be_flow
  end
  it "should work create an omrl from a name and a context" do
    omrl = OMRL.new("ca","us")
    omrl.to_s.should == "us.ca"
    omrl.should_not be_flow
  end
  it "should work create an omrl from an omrl string" do
    omrl = OMRL.new("us.ny.cc.can.zippy")
    omrl.to_s.should == "us.ny.cc.can.zippy"
    omrl.should_not be_flow
  end
  it "should work create an omrl from an omrl string" do
    omrl = OMRL.new("us.ny.cc.can.zippy/23")
    omrl.to_s.should == "us.ny.cc.can.zippy/23"
    omrl.should be_flow
  end
end

describe "root omrl" do
  it "should create from nil" do
    omrl = OMRL.new(nil)
    omrl.to_s.should == ''
  end
  it "should create from ''" do
    omrl = OMRL.new('')
    omrl.to_s.should == ''
  end
  it "should return nil for parent context" do
    omrl = OMRL.new(nil)
    omrl.parent_context.should == nil
  end
end
describe "omrls resolution" do
  fixtures :entities
  fixtures :links

  it "should resolve the root omrl" do
    omrl = OMRL.new('')
    omrl.url.should == "/entities/1"
  end

  it "should resolve context omrls" do
    omrl = OMRL.new('us')
    omrl.url.should == "/entities/" << entities(:context_us).id.to_s
  end

  it "should resolve account omrls" do
    omrl = OMRL.new('us.zippy')
    omrl.url.should == "/entities/" << entities(:account_zippy).id.to_s
  end

  it "should resolve flow omrls" do
    omrl = OMRL.new('us.zippy/' << entities(:flow_tx1).id.to_s)
    omrl.url.should == "/entities/" << entities(:flow_tx1).id.to_s
  end

  it "should resolve currency absolute omrls" do
    omrl = OMRL.new('us.bucks')
    omrl.url.should == "/entities/" << entities(:currency_bucks).id.to_s
  end
  
end

describe "An omrl" do
  fixtures :entities
  fixtures :links
  before(:each) do
    @omrl = OMRL.new("us.zippy")
  end
  it "should convert to a url" do
    @omrl.url.should == "/entities/" << entities(:account_zippy).id.to_s
  end
end

#describe "An entity url" do
#  fixtures :entities
#  fixtures :links
#  
#  it "should convert to an omrl" do
#    OMRL.url_to_omrl("/entities/6").should == "ca.mwl"
#  end
#end

