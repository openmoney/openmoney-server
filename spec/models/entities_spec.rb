require File.dirname(__FILE__) + '/../spec_helper'

describe "Creating an entity (in general)" do

  it "should fail for an unknown entity type" do
    lambda {e = Entity.create({
      :entity_type => "bogus_entity_type",
      :specification => <<-eos
        eos
    })}.should raise_error
  end

  it "should not fail for an known entity type" do
    lambda {e = Entity.create({
      :entity_type => "context",
      :specification => <<-eos
        eos
    })}.should_not raise_error
  end

end

describe "fixtures" do
  fixtures :entities
  fixtures :links
  
  it "relative entity omrls" do
    entities(:account_zippy).omrl.should == "zippy^"
    entities(:context_us).omrl.should == "us."
    entities(:context_ca).omrl.should == "ca."
    entities(:currency_bucks).omrl.should == "bucks~"
    entities(:flow_tx1).omrl.should == 'zippy#7^us.'
    entities(:account_mwl).omrl.should == "mwl^"
  end
  
  it "absolute entity omrls" do
    entities(:account_zippy).omrl(false).should == "zippy^us."
    entities(:currency_bucks).omrl(false).should == "bucks~us."
    entities(:flow_tx1).omrl(false).should == 'zippy#7^us.'
    entities(:account_mwl).omrl(false).should == "mwl^ca."
    entities(:context_us).omrl(false).should == "us."
    entities(:context_ca).omrl(false).should == "ca."
  end
  
  it "find_by_omrl should find unspecified relative omrls" do
    Entity.find_by_omrl("mwl^").should == entities(:account_mwl)
#    Entity.find_by_omrl("zippy#7").should == entities(:flow_tx1)  see TODO below
    Entity.find_by_omrl("bob^").should be_nil
  end

  it "find_by_omrl should find specified relative omrl" do
    Entity.find_by_omrl("mwl^").should == entities(:account_mwl)
    Entity.find_by_omrl("bucks~").should == entities(:currency_bucks)

#    Entity.find_by_omrl("zippy#7^").should == entities(:flow_tx1)
#TODO figure out how/if this should work.  Right now you can't confirm
# the declarer because the declares link is stored as the full omrl (zippy^us.)
# so the relative omrl doesn't match in the search.

    Entity.find_by_omrl("bob^").should be_nil
  end

  it "find_by_omrl should find absolute omrls" do
    Entity.find_by_omrl("mwl^ca").should == entities(:account_mwl)
    Entity.find_by_omrl("bucks~us").should == entities(:currency_bucks)
    Entity.find_by_omrl("zippy#7^us").should == entities(:flow_tx1)
    Entity.find_by_omrl("ca.").should == entities(:context_ca)
    Entity.find_by_omrl("zippy#7^ca").should be_nil
  end

#  specify "find_by_omrl should not find entities for bad omrl" do
#    Entity.find_by_omrl("xxx").should == nil
#  end

end