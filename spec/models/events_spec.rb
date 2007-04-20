require File.dirname(__FILE__) + '/../spec_helper'

module EventSpecHelper
  def valid_attributes
    { :event_type => 'CreateAccount',
      :specification => "some spec"}
  end
end

context "An event (in general)" do
  include EventSpecHelper

  setup do
    @p = Event.new
  end

  specify "should be invalid without an event_type" do
    @p.attributes = valid_attributes.reject {|k,v|  k == :event_type}
    @p.should_not_be_valid
  end

  specify "should be invalid without a specification" do
    @p.attributes = valid_attributes.reject {|k,v|  k == :specification}
    @p.should_not_be_valid
  end

  specify "should be valid with a full set of valid attributes" do
    @p.attributes = valid_attributes
    @p.should_be_valid
  end
end

#Delete this context and add some real ones
context "Given a generated event_spec.rb with fixtures loaded" do
  fixtures :events

  specify "fixtures should load two Events" do
    Event.should have(2).records
  end
end
