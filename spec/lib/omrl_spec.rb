require File.dirname(__FILE__) + '/../spec_helper'

context "A local omrl" do
  specify "should report local?" do
    omrl = OMRL.new(1)
    omrl.should_be_local
  end
end

context "A non local omrl" do
  specify "should fail to report local?" do
    omrl = OMRL.new(66)
    omrl.should_not_be_local
  end
end

context "An OM_NAME omrl" do
  setup do
    @omrl = OMRL.new("zippy")
  end
  specify "should be of type OM_NAME" do
    @omrl.type.should == OMRL::OM_NAME
  end
  specify "should convert to a num" do
    @omrl.num.should == "4"
  end
  specify "should convert to a url" do
    @omrl.url.should == "/entities/4"
  end
end

context "An OM_NUM omrl" do
  setup do
    @omrl = OMRL.new(1)
  end
  specify "should be of type OM_NUM" do
    @omrl.type.should == OMRL::OM_NUM
  end
  specify "should convert to a num" do
    @omrl.num.should == "1"
  end
  specify "should convert to a name" do
    @omrl.name.should == "ca"
  end
  specify "should convert to a url" do
    @omrl.url.should == "/entities/1"
  end
end

context "An OM_URL omrl" do
  setup do
    @omrl = OMRL.new("/entities/5")
  end
  specify "should be of type OM_URL" do
    @omrl.type.should == OMRL::OM_URL
  end
  specify "should convert to a name" do
    @omrl.name.should == "mwl"
  end
  specify "should convert to a num" do
    @omrl.num.should == "5"
  end
  specify "should convert to a url" do
    @omrl.url.should == "/entities/5"
  end
end

