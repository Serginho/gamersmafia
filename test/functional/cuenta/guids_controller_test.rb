# -*- encoding : utf-8 -*-
require 'test_helper'

class Cuenta::GuidsControllerTest < ActionController::TestCase
  test_min_acl_level :user, [ :index, :guardar ]



  test "index_should_work" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "guardar_should_work_if_giving_reason" do
    sym_login 1
    @u1 = User.find(1)
    @g1 = Game.find(1)
    post :guardar, { "guid#{@g1.id}" => {:guid => '0123456789', :reason => 'soy feo'}}
    assert_response :redirect
    assert_equal '0123456789', @u1.users_guids.find_last_by(@u1, @g1).guid
  end

  test "guardar_shouldnt_throw_500_if_duped" do
    test_guardar_should_work_if_giving_reason
    sym_login 2
    @u2 = User.find(2)
    @g1 = Game.find(1)
    post :guardar, { "guid#{@g1.id}" => {:guid => '0123456789', :reason => 'soy feo'}}
    assert_response :redirect
    assert_not_nil flash[:error]
    assert_nil @u2.users_guids.find_last_by(@u2, @g1)
  end

  test "guardar_should_work_if_doing_nothing" do
    test_guardar_should_work_if_giving_reason
    post :guardar, { "guid#{@g1.id}" => {:guid => '0123456789', :reason => ''}}
    assert_response :redirect
    assert_nil flash[:error]
  end

  test "guardar_shouldnt_work_if_changing_without_giving_reason" do
    test_guardar_should_work_if_giving_reason
    post :guardar, { "guid#{@g1.id}" => {:guid => '0123456788', :reason => ''}}
    assert_response :redirect
    assert_not_nil flash[:error]
    assert_equal '0123456789', @u1.users_guids.find_last_by(@u1, @g1).guid
  end
end
