# -*- encoding : utf-8 -*-
require 'test_helper'

class Cuenta::FaccionControllerTest < ActionController::TestCase
  test "should_be_able_to_join_a_faction" do
    u = User.find_by_login('panzer')
     (u.faction_id = nil && u.save) if u.faction_id
    sym_login :panzer
    post :join, :id => Faction.find(1).id
    assert_redirected_to :action => :index
    u.reload
    assert_equal 1, u.faction_id
  end

  test "should_be_able_to_join_null_faction" do
    u = User.find_by_login('panzer')
     (u.faction_id = nil && u.save) if u.faction_id
    sym_login :panzer
    post :join, :id => ''
    assert_redirected_to :action => :index
    u.reload
    assert_nil u.faction_id
  end

  test "staff_should_work_if_faction_leader" do
    f1 = Faction.find(1)
    assert f1.update_boss(User.find(1))
    u1 = User.find(1)
    u1.faction_id = 1
    assert u1.save
    sym_login 1
    get :staff
    assert_response :success
  end

  test "add_editor_should_work" do
    test_staff_should_work_if_faction_leader
    @panzer = User.find_by_login('panzer')
    @ctype = ContentType.find_by_name('News')
    assert_count_increases(UsersSkill) do
      post :add_editor, :content_type_id => @ctype.id, :login => @panzer.login
    end
    assert_response :redirect, @response.body
  end

  test "add_editor_shouldnt_break_if_existing" do
    test_add_editor_should_work
    post :add_editor, :content_type_id => @ctype.id, :login => @panzer.login

    assert_response :success
    assert_not_nil flash[:error]
  end

  test "del_editor_should_work" do
    test_add_editor_should_work
    assert_count_decreases(UsersSkill) do
      post :del_editor, {:id =>  @panzer.id, :content_type_id => @ctype.id }
    end
    assert_response :redirect
  end

  test "add_moderator_should_work" do
    test_staff_should_work_if_faction_leader
    assert_count_increases(UsersSkill) do
      post :add_moderator, {:login => 'panzer'}
    end
    assert_response :redirect
  end

  test "add_moderator_should_warn_if_null_user_id" do
    test_staff_should_work_if_faction_leader

    post :add_moderator, {:login => ''}

    assert_response :success
    assert_not_nil flash[:error]
  end


  test "add_moderator_shouldnt_break_if_already_existing" do
    test_add_moderator_should_work
    post :add_moderator, {:login => 'panzer'}
    assert_response :success
    assert_not_nil flash[:error]
  end

  test "links_should_work" do
    test_staff_should_work_if_faction_leader
    get :links
    assert_response :success
  end

  test "links_new_should_work" do
    test_staff_should_work_if_faction_leader
    get :links_new
    assert_response :success
  end

  test "links_create_should_work" do
    test_staff_should_work_if_faction_leader
    assert_count_increases(FactionsLink) do
      post :links_create, { :factions_link => { :name => 'foo linky', :url => 'http://bar.com', :image => fixture_file_upload('files/buddha.jpg', 'image/jpeg')}}
    end
    assert_response :redirect
    @fl = FactionsLink.find(:first, :order => 'id desc')
  end

  test "links_edit_should_work" do
    test_links_create_should_work
    get :links_edit, :id => FactionsLink.find(:first, :order => 'id desc').id
    assert_response :success
  end

  test "links_update_should_work" do
    test_links_create_should_work
    assert_not_equal 'succubus', @fl.name
    post :links_update, :id => @fl.id, :factions_link => {:name => 'succubus'}
    assert_response :redirect
    @fl.reload
    assert_equal 'succubus', @fl.name
  end

  test "links_destroy" do
    test_links_create_should_work
    assert_count_decreases(FactionsLink) do
      post :links_destroy, :id => @fl.id
    end
  end

  test "cabeceras_should_work" do
    test_staff_should_work_if_faction_leader
    get :cabeceras
    assert_response :success
  end

  test "cabeceras_new_should_work" do
    test_staff_should_work_if_faction_leader
    get :cabeceras_new
    assert_response :success
  end

  test "cabeceras_create_should_work" do
    test_staff_should_work_if_faction_leader
    assert_count_increases(FactionsHeader) do
      post :cabeceras_create, { :factions_header => { :name => 'el nombre', :file => fixture_file_upload('files/buddha.jpg', 'image/jpeg')}}
    end
    assert_response :redirect
    @fl = FactionsHeader.find(:first, :order => 'id desc')
  end

  test "cabeceras_edit_should_work" do
    test_cabeceras_create_should_work
    get :cabeceras_edit, :id => FactionsHeader.find(:first, :order => 'id desc').id
    assert_response :success
  end

  test "cabeceras_update_should_work" do
    test_cabeceras_create_should_work
    assert_not_equal 'succubus', @fl.name
    post :cabeceras_update, :id => @fl.id, :factions_header => {:file => fixture_file_upload('files/babe.jpg', 'image/jpeg')}
    assert_response :redirect
  end

  test "cabeceras_destroy" do
    test_cabeceras_create_should_work
    assert_count_decreases(FactionsHeader) do
      post :cabeceras_destroy, :id => @fl.id
    end
  end

  test "mapas_juegos_should_work" do
    test_staff_should_work_if_faction_leader
    get :mapas_juegos
    assert_response :success
  end

  test "mapas_juegos_new_should_work" do
    test_staff_should_work_if_faction_leader
    get :mapas_juegos_new
    assert_response :success
  end

  test "mapas_juegos_create_should_work" do
    test_staff_should_work_if_faction_leader
    assert_count_increases(GamesMap) do
      post :mapas_juegos_create, { :games_map => { :name => 'el nombre', :screenshot => fixture_file_upload('files/buddha.jpg', 'image/jpeg')}}
    end
    assert_response :redirect
    @fl = GamesMap.find(:first, :order => 'id desc')
  end

  test "mapas_juegos_edit_should_work" do
    test_mapas_juegos_create_should_work
    get :mapas_juegos_edit, :id => GamesMap.find(:first, :order => 'id desc').id
    assert_response :success
  end

  test "mapas_juegos_update_should_work" do
    test_mapas_juegos_create_should_work
    assert_not_equal 'succubus', @fl.name
    post :mapas_juegos_update, :id => @fl.id, :games_map => {:name => 'dm-tower', :screenshot => fixture_file_upload('files/babe.jpg', 'image/jpeg')}
    assert_response :redirect
    @fl.reload
    assert_equal 'dm-tower', @fl.name
  end

  test "mapas_juegos_destroy" do
    test_mapas_juegos_create_should_work
    assert_count_decreases(GamesMap) do
      post :mapas_juegos_destroy, :id => @fl.id
    end
  end

  test "del_moderator_should_work" do
    test_add_moderator_should_work
    assert_count_decreases(UsersSkill) do
      post :del_moderator, {:id => UsersSkill.find(:first, :order => 'id desc').user_id }
    end
    assert_response :redirect
  end

  test "should_show_index_without_entering_a_faction" do
    sym_login :panzer
    get :index
    assert_response :success
    assert_template 'index'
  end

  test "should_show_index_after_entering_a_faction" do
    test_should_be_able_to_join_a_faction
    get :index
    assert_response :success
    assert_template 'index'
  end

  test "should_be_able_to_ban_user" do
    @f1 = Faction.find(1)
    u1 = User.find(1)
    u1.faction_id = 1
    assert u1.save
    sym_login 1
    post :ban_user, { :login => 'panzer', :reason => 'feo del culo'}
    assert_response :redirect
    assert_equal true, @f1.user_is_banned?(User.find_by_login(:panzer))
  end

  test "unban_should_work" do
    test_should_be_able_to_ban_user
    post :unban_user, { :login => 'panzer' }
    assert !@f1.user_is_banned?(User.find_by_login(:panzer))
  end

  test "bans_should_work" do
    test_staff_should_work_if_faction_leader
    get :bans
    assert_response :success
  end

  test "should_be_able_to_ban_user_with_spaces" do
    f1 = Faction.find(1)
    u1 = User.find(1)
    u1.faction_id = 1
    assert_equal true, u1.save
    sym_login 1
    post :ban_user, { :login => ' panzer ', :reason => 'feo del culo'}
    assert_response :redirect
    assert_equal true, f1.user_is_banned?(User.find_by_login(:panzer))
  end

  test "juego_should_work" do
    f1 = Faction.find(1)
    u1 = User.find(1)
    u1.faction_id = 1
    assert f1.update_boss(u1)
    # assert_equal true, u1.save
    sym_login 1
    get :juego
    assert_response :success
  end

  test "informacion" do
    test_staff_should_work_if_faction_leader
    get :informacion
    assert_response :success
  end

  test "informacion_update_should_work" do
    test_staff_should_work_if_faction_leader
    post :informacion_update, {:faction => {:description => 'soy la descripcion de una faccion'}}
    assert_equal 'soy la descripcion de una faccion', Faction.find(1).description
    assert_response :redirect
  end

  def atest_new_in_gm
    test_staff_should_work_if_faction_leader
    get :categorias_new, {:type_name => 'Topic' }

    assert_response :success
    assert_template 'categorias_new'

    assert_not_nil assigns(:category)
  end

  def atest_create_in_gm
    test_staff_should_work_if_faction_leader
    num_topics_category = TopicsCategory.count

    post :categorias_create, {:type_name => 'Topic', :category => {:parent_id => '1', :name => 'foo_forum', :code => 'foo_code'}}

    assert_response :redirect, @response.body

    assert_equal num_topics_category + 1, TopicsCategory.count
  end

  def atest_edit_in_gm
    test_staff_should_work_if_faction_leader
    get :categorias_edit, {:type_name => 'Topic', :id => 1}

    assert_response :success
    assert_template 'categorias_edit'
  end

  def atest_update_in_gm
    test_create_in_gm
    tc = TopicsCategory.find(:first, :order => 'id desc')
    post :categorias_update, {:type_name => 'Topic', :id => tc.id, :category => {:parent_id => tc.parent_id.to_s}}
    assert_response :redirect, flash[:error]
  end

  def atest_destroy_confirm_in_gm
    test_staff_should_work_if_faction_leader
    assert_not_nil TopicsCategory.find(1)

    post :category_destroy_confirm, {:type_name => 'Topic', :id => 1}
    assert_response :redirect

    assert_raise(ActiveRecord::RecordNotFound) {
      TopicsCategory.find(1)
    }
  end


  test "create_games_mode" do
    test_staff_should_work_if_faction_leader
    assert_count_increases(GamesMode) do
      post :create_games_mode, {:games_mode => { :game_id => 1, :entity_type => Game::ENTITY_USER, :name => 'CTF2'}}, { :user => 1 }
      assert_redirected_to '/cuenta/faccion/juego'
    end
  end

  test "create_games_version" do
    test_staff_should_work_if_faction_leader
    assert_count_increases(GamesVersion) do
      post :create_games_version, {:games_version => { :game_id => 1, :version => '0.99'}}, { :user => 1 }
      assert_redirected_to '/cuenta/faccion/juego'
    end
  end

  test "destroy_games_mode" do
    test_create_games_mode
    assert_count_decreases(GamesMode) do
      post :destroy_games_mode, { :id => GamesMode.find(:first, :order => 'id DESC').id }, { :user => 1 }
      assert_redirected_to '/cuenta/faccion/juego'
    end
  end

  test "destroy_games_version" do
    test_create_games_version
    assert_count_decreases(GamesVersion) do
      post :destroy_games_version, { :id => GamesVersion.find(:first, :order => 'id DESC').id }, { :user => 1 }
      assert_redirected_to '/cuenta/faccion/juego'
    end
  end

  test "update_underboss_should_work" do
    f1 = Faction.find(1)
    assert f1.update_boss(User.find(1))
    u1 = User.find(1)
    u1.faction_id = f1.id
    assert u1.save
    u1.reload
    sym_login u1.id
    post :update_underboss, {:id => f1.id, :login => 'panzer'}
    assert_response :redirect
    f1.reload
    assert f1.is_underboss?(User.find_by_login('panzer'))

    post :update_underboss, {:id => f1.id, :login => ''}
    assert_response :redirect
    f1.reload
    assert !f1.has_underboss?
  end
end
