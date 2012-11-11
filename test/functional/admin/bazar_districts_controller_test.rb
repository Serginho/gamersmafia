# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::BazarDistrictsControllerTest < ActionController::TestCase

  test "index no skill" do
    sym_login 1
    assert_raises(AccessDenied) do
      get :index
    end
    assert_response :success
  end

  test "index" do
    give_skill(1, "BazarManager")
    sym_login 1
    get :index
    assert_response :success
  end

  test "create" do
    give_skill(1, "BazarManager")
    sym_login 1
    assert_count_increases(BazarDistrict) do
      post :create, {:bazar_district => {:name => 'el nombrecico', :slug => 'codecico'}}
      assert_redirected_to "/admin/bazar_districts"
    end
  end

  test "edit" do
    give_skill(1, "BazarManager")
    sym_login 1
    get :edit, :id => 1
    assert_response :success
  end

  test "update" do
    give_skill(1, "BazarManager")
    sym_login 1
    u1 = User.find(1)
    u2 = User.find(2)
    post :update, :id => 1, :don => u1.login, :mano_derecha => u2.login
    assert_redirected_to "/admin/bazar_districts/edit/1"
    bd = BazarDistrict.find(1)
    assert_equal 1, bd.don.id
    assert_equal 2, bd.mano_derecha.id
  end
end
