require 'test_helper'
load Rails.root + '/Rakefile'

class DailyRakeTest < ActiveSupport::TestCase
  include Rake

  def setup
    overload_rake_for_tests
  end

  test "should_properly_close_old_open_questions" do
    q = Question.find(1)
    assert_nil q.answered_on
    c = Comment.count
    Rake::Task['gm:daily'].send :close_old_open_questions
    q.reload
    assert_not_nil q.answered_on
    assert_equal c + 1, Comment.count
  end

  test "should_properly_close_old_open_questions_recent_question" do
    User.db_query("UPDATE questions SET created_on = now() - '1 day'::interval WHERE id = 1")
    q = Question.find(1)
    assert_nil q.answered_on
    c = Comment.count
    Rake::Task['gm:daily'].send :close_old_open_questions
    q.reload
    assert_nil q.answered_on
    assert_equal c, Comment.count
  end

  test "should_properly_set_daily_ads_stats" do
    adslot = AdsSlot.new(:name => 'foo', :behaviour_class => 'Random', :location => 'bottom')
    assert adslot.save

    ad = Ad.new(:name => 'fulanito de tal', :file => fixture_file_upload('files/buddha.jpg'), :link_file => 'google.com')
    assert ad.save

    adsi = AdsSlotsInstance.new(:ads_slot_id => adslot.id, :ad_id => ad.id)
    assert adsi.save

    pc_init = User.db_query("SELECT count(*) FROM stats.pageviews")[0]['count'].to_i

    # p [adsi.id.to_s].to_yaml
    sym_pageview :url => 'fooo', :ads_shown => [adsi.id.to_s].to_yaml
    sym_pageview :url => 'f2ooo', :ads_shown => [adsi.id.to_s].to_yaml
    sym_pageview :url => 'f2ooo', :ads_shown => [adsi.id.to_s].to_yaml

    # puts User.db_query("SELECT ads_shown FROM stats.pageviews ORDER BY id DESC LIMIT 1")
    User.db_query("UPDATE stats.pageviews set created_on = created_on - '1 day'::interval;")
    assert_equal pc_init + 3, User.db_query("SELECT count(*) FROM stats.pageviews")[0]['count'].to_i
    User.db_query("INSERT INTO stats.ads(element_id, url, ip) VALUES('adsi#{adsi.id}', 'adad', '127.0.0.1')")
    User.db_query("UPDATE stats.ads set created_on = created_on - '1 day'::interval;")

    Rake::Task['gm:daily'].send :generate_daily_ads_stats
    dbl = User.db_query("SELECT * FROM stats.ads_daily WHERE ads_slots_instance_id = #{adsi.id} ORDER BY id DESC LIMIT 1")

    assert_equal 1, dbl.size
    assert_equal 1, dbl[0]['hits'].to_i
    assert_equal 3, dbl[0]['pageviews'].to_i
  end

  test "should_send_report_if_on_due_day" do
    User.db_query("UPDATE advertisers SET due_on_day = extract('day' from now() - '2 days'::interval)")
    adv = Advertiser.find(:first)
    adv.due_on_day = Time.now.day
    assert_equal true, adv.save
    deliveries = ActionMailer::Base.deliveries.size
    Rake::Task['gm:daily'].send :send_reports_to_publisher_if_on_due_date
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
    assert /Informe/ =~ ActionMailer::Base.deliveries.last.subject
  end

  test "should_send_birthday_email_to_users" do
    u = User.find_by_login(:panzer)
    assert_not_nil u
    # el año - 4 en caso de que sea bisiesto
    u.birthday = Date.new(Date.today.year - 4, Date.today.month, Date.today.day)
    u.notifications_newmessages = true
    u.save
    deliveries = ActionMailer::Base.deliveries.size
    Rake::Task['gm:daily'].send :send_happy_birthday
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
    assert /Feliz cumplea/ =~ ActionMailer::Base.deliveries.last.subject
  end

  test "should_update_faith_of_users_with_zombie_refered" do
    u2 = User.find(2)
    u2.state = User::ST_ACTIVE
    u2.referer_user_id = 1
    assert_equal true, u2.save
    u1 = User.find(1)
    u1.cache_faith_points = nil
    fp = u1.faith_points
    User.db_query("UPDATE users SET lastseen_on = now() - '3 months 1 day'::interval where id = 2")
    Rake::Task['gm:daily'].send :clear_faith_points_of_referers_and_resurrectors
    u1.reload
    assert_equal fp - Faith::FPS_ACTIONS['registration'], u1.faith_points
  end

  test "should_update_faith_of_users_with_zombie_resurrected" do
    u2 = User.find(2)
    u2.state = User::ST_ACTIVE
    u2.resurrected_by_user_id = 1
    assert_equal true, u2.save
    u1 = User.find(1)
    u1.cache_faith_points = nil
    fp = u1.faith_points
    User.db_query("UPDATE users SET lastseen_on = now() - '3 months 1 day'::interval where id = 2")
    Rake::Task['gm:daily'].send :clear_faith_points_of_referers_and_resurrectors
    u1.reload
    assert_equal fp - Faith::FPS_ACTIONS['resurrection'], u1.faith_points
  end

  test "should_send_1w_confirmation_email" do
    User.db_query("UPDATE users SET updated_at = now() - '4 days'::interval, state=#{User::ST_UNCONFIRMED} WHERE id = 1")
    Rake::Task['gm:daily'].send :new_accounts_cleanup
    u1 = User.find(1)
    assert_equal User::ST_UNCONFIRMED_1W, u1.state
  end

  test "should_send_2w_confirmation_email" do
    User.db_query("UPDATE users SET updated_at = now() - '4 days'::interval, state=#{User::ST_UNCONFIRMED_1W} WHERE id = 1")
    Rake::Task['gm:daily'].send :new_accounts_cleanup
    u1 = User.find(1)
    assert_equal User::ST_UNCONFIRMED_2W, u1.state
  end

  test "should_set_accounts_as_deleted" do
    User.db_query("UPDATE users SET updated_at = now() - '4 days'::interval, state=#{User::ST_UNCONFIRMED_2W} WHERE id = 1")
    Rake::Task['gm:daily'].send :new_accounts_cleanup
    u1 = User.find(1)
    assert_equal User::ST_DELETED, u1.state
  end

  test "should_automatically_send_unanswered_challenge_email_first_time" do
    l = Ladder.find(:first, :conditions => ['competitions_participants_type_id = ? and pro is false and state = ? and fee is null and invitational is false', Competition::USERS, Competition::STARTED])
    assert_not_nil l
    u1 = User.find(1)
    u2 = User.find(2)
    cp1 = l.join(u1)
    cp2 = l.join(u2)
    cm = l.challenge(cp1, cp2)
    User.db_query("UPDATE competitions_matches SET updated_on = now() - '2 weeks'::interval")
    assert_count_increases(ActionMailer::Base.deliveries) do
      Rake::Task['gm:daily'].send :check_ladder_matches
    end
  end

  test "should_automatically_send_unanswered_challenge_email_second_time" do
    l = Ladder.find(:first, :conditions => ['competitions_participants_type_id = ? and pro is false and state = ? and fee is null and invitational is false', Competition::USERS, Competition::STARTED])
    assert_not_nil l
    u1 = User.find(1)
    u2 = User.find(2)
    cp1 = l.join(u1)
    cp2 = l.join(u2)
    cm = l.challenge(cp1, cp2)
    User.db_query("UPDATE competitions_matches SET updated_on = now() - '25 days'::interval")
    assert_count_increases(ActionMailer::Base.deliveries) do
      Rake::Task['gm:daily'].send :check_ladder_matches
    end
  end

  test "should_automatically_cancel_unanswered_challenges_after_enough_time" do
    l = Ladder.find(:first, :conditions => ['competitions_participants_type_id = ? and pro is false and state = ? and fee is null and invitational is false', Competition::USERS, Competition::STARTED])
    assert_not_nil l
    u1 = User.find(1)
    u2 = User.find(2)
    cp1 = l.join(u1)
    cp2 = l.join(u2)
    cm = l.challenge(cp1, cp2)
    User.db_query("UPDATE competitions_matches SET updated_on = now() - '35 days'::interval")
    assert_count_decreases(CompetitionsMatch) do
      assert_count_increases(ActionMailer::Base.deliveries) do
        Rake::Task['gm:daily'].send :check_ladder_matches
      end
    end
  end

  test "should_automatically_accept_unconfirmed_result_after_1_month" do
    l = Ladder.find(:first, :conditions => ['competitions_participants_type_id = ? and pro is false and state = ? and fee is null and invitational is false', Competition::USERS, Competition::STARTED])
    assert_not_nil l
    u1 = User.find(1)
    u2 = User.find(2)
    cp1 = l.join(u1)
    cp2 = l.join(u2)
    cm = l.challenge(cp1, cp2)
    cm.accept_challenge
    cm.complete_match(u2, {:result => 1}, true)
    assert_nil cm.completed_on
    User.db_query("UPDATE competitions_matches SET updated_on = now() - '32 days'::interval")
    Rake::Task['gm:daily'].send :check_ladder_matches
    cm.reload
    assert_not_nil cm.completed_on
  end

  test "should_automatically_forfeit_unset_result_after_1_month" do
    [Competition::SCORING_SIMPLE, Competition::SCORING_PARTIAL, Competition::SCORING_SIMPLE_PER_MAP].each do |scoring_mode|
      l = Ladder.find(:first, :conditions => ["scoring_mode = ? AND competitions_participants_type_id = ? and pro is false and state = ? and fee is null and invitational is false", scoring_mode, Competition::USERS, Competition::STARTED])
      assert_not_nil l
      u1 = User.find(1)
      u2 = User.find(2)
      cp1 = l.join(u1)
      cp2 = l.join(u2)
      cm = l.challenge(cp1, cp2)
      cm.accept_challenge

      assert_nil cm.completed_on
      User.db_query("UPDATE competitions_matches SET updated_on = now() - '32 days'::interval")
      Rake::Task['gm:daily'].send :check_ladder_matches
      cm.reload
      assert_not_nil cm.completed_on
    end
  end

  test "update_max_cache_valorations_weights_on_self_comments" do
      Rake::Task['gm:daily'].send(
          :update_max_cache_valorations_weights_on_self_comments)
  end
end
