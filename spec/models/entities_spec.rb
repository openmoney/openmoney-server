require File.dirname(__FILE__) + '/../spec_helper'

context "Creating an entity (in general)" do

  specify "should fail for an unknown entity type" do
    lambda {e = Entity.create({
      :entity_type => "bogus_entity_type",
      :specification => <<-eos
        name: ec
        eos
    })}.should raise_error
  end

  specify "should not fail for an known entity type" do
    lambda {e = Entity.create({
      :entity_type => "context",
      :specification => <<-eos
        name: ec
        eos
    })}.should_not raise_error
  end

end
