require File.dirname(__FILE__) + '/../spec_helper'

describe CurrenciesController do

  #Delete these examples and add some real ones
  it "should use CurrenciesController" do
    controller.should be_an_instance_of(CurrenciesController)
  end


  it "GET 'new' should be successful" do
    get 'new'
    response.should be_success
  end
end
