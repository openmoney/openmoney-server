require File.dirname(__FILE__) + '/../spec_helper'


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

