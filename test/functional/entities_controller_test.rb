require File.dirname(__FILE__) + '/../test_helper'
require 'entities_controller'

# Re-raise errors caught by the controller.
class EntitiesController; def rescue_action(e) raise e end; end

class EntitiesControllerTest < Test::Unit::TestCase
  fixtures :entities

  def setup
    @controller = EntitiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:entities)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_entity
    old_count = Entity.count
    post :create, :entity => { }
    assert_equal old_count+1, Entity.count
    
    assert_redirected_to entity_path(assigns(:entity))
  end

  def test_should_show_entity
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_entity
    put :update, :id => 1, :entity => { }
    assert_redirected_to entity_path(assigns(:entity))
  end
  
  def test_should_destroy_entity
    old_count = Entity.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Entity.count
    
    assert_redirected_to entities_path
  end
end
