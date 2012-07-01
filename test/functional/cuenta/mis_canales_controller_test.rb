require 'test_helper'

class Cuenta::MisCanalesControllerTest < ActionController::TestCase
  test "index_should_work" do
    sym_login 1
    get :index
    assert_response :success
    assert_template 'index'
  end

  test "editar_should_work" do
    sym_login 1
    get :editar, { :id => 1 }
    assert_response :success
    assert_template 'editar'
  end

  test "update_should_work" do
    sym_login 1
    channel1 = GmtvChannel.find(:first, :conditions => 'user_id = 1')
    assert_not_nil channel1
    prev_h = channel1.file
    post :update, { :id => 1, :gmtv_channel => { :file => fixture_file_upload('files/header.swf')} }
    assert_redirected_to '/cuenta/mis_canales/editar/1'
    channel1.reload
    assert_equal false, (channel1.file == prev_h)
  end
end
