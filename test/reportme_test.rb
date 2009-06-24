require 'test_helper'

class ReportmeTest < Test::Unit::TestCase

  def setup
    exec("use report_me_test")
    exec "drop table if exists visits"
    exec <<-SQL
      create
        table visits
        (
          id bigint auto_increment,
          channel varchar(255),
          created_at datetime,
          primary key (id)
        )
    SQL
  end
  
  def create_visit_report_factory(opts={})
    
    defaults = {
      :periods => [],
      :since => DateTime.now
    }
    
    opts = defaults.merge(opts)
    
    @rme = Reportme::ReportFactory.create opts[:since] do
      report :visits do
        periods opts[:periods]
        source do |von, bis|
          <<-SQL
          select
            '#{von}' as von,
            date(created_at) as datum,
            channel,
            count(1) as cnt
          from
            visits
          where
            created_at between '#{von}' and '#{bis}'
          group by
            date(created_at),
            channel
          SQL
        end
      end
    end
    @rme
  end
  
  def exec(sql)
    ActiveRecord::Base.connection.execute(sql)
  end

  def one(sql)
    ActiveRecord::Base.connection.select_one(sql)
  end

  def teardown
    unless @debug
      @rme.reset if @rme
      exec("truncate visits;");
    end
  end

  should "create one visitor in the today report for channel sem" do
    exec("insert into visits values (null, 'sem', now())");
    create_visit_report_factory.run
    assert_equal 1, one("select count(1) as cnt from visits_today where channel = 'sem' and datum = curdate()")["cnt"].to_i
  end
  
  should "create two visitors in the today report for channel sem" do
    exec("insert into visits values (null, 'sem', now())");
    exec("insert into visits values (null, 'sem', now())");
    create_visit_report_factory.run
    assert_equal 2, one("select cnt from visits_today where channel = 'sem' and datum = curdate()")["cnt"].to_i
  end
  
  should "create visitors in the today report for channel sem and seo" do
    exec("insert into visits values (null, 'sem', now())");
    exec("insert into visits values (null, 'sem', now())");
    exec("insert into visits values (null, 'seo', now())");
    exec("insert into visits values (null, 'sem', now())");
    exec("insert into visits values (null, 'seo', now())");
    create_visit_report_factory.run
    assert_equal 2, one("select cnt from visits_today where channel = 'seo' and datum = curdate()")["cnt"].to_i
    assert_equal 3, one("select cnt from visits_today where channel = 'sem' and datum = curdate()")["cnt"].to_i
  end
  
  should "create visitors in the day report for channel sem and seo" do
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 1 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 1 day));");
    exec("insert into visits values (null, 'seo', date_sub(curdate(), interval 1 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 1 day));");
    exec("insert into visits values (null, 'seo', date_sub(curdate(), interval 1 day));");
    create_visit_report_factory(:periods => [:today, :day]).run
    assert_equal 2, one("select cnt from visits_day where channel = 'seo' and datum = date_sub(curdate(), interval 1 day)")["cnt"].to_i
    assert_equal 3, one("select cnt from visits_day where channel = 'sem' and datum = date_sub(curdate(), interval 1 day)")["cnt"].to_i
  end
  
  should "report a week as 7 days since yesterday ignoring days before or after this" do
  
    # today should be ignored
    exec("insert into visits values (null, 'sem', curdate());");
  
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 1 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 2 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 3 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 4 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 5 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 6 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 7 day));");
    
    # 8 days ago should be ignored
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 8 day));");
    
    create_visit_report_factory(:periods => [:week]).run
    assert_equal 7, one("select count(1) as cnt from visits_week where channel = 'sem' and von = date_sub(curdate(), interval 7 day)")["cnt"].to_i
  end
  
  should "create a daily report for the previous 3 days" do
  
    #should be ignored
    exec("insert into visits values (null, 'sem', curdate());");
  
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 1 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 2 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 3 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 4 day));");
  
    # should be ignored
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 5 day));");
  
    create_visit_report_factory(:since => 3.days.ago,:periods => [:day]).run
    assert_equal 4, one("select count(1) as cnt from visits_day where von between date_sub(curdate(), interval 4 day) and date_sub(curdate(), interval 1 day)")["cnt"].to_i
  end
  
  should "create the weekly report by using 7 daily reports" do
    
    # should be ignored in weekly
    exec("insert into visits values (null, 'sem', curdate());");
  
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 1 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 2 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 3 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 4 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 5 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 6 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 7 day));");
    
    # should be ignored in weekly
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 8 day));");
    # should be ignored in weekly
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 9 day));");

    create_visit_report_factory(:since => 10.days.ago,:periods => [:day]).run
    
    exec("truncate visits;")

    create_visit_report_factory(:periods => [:week]).run

    assert_equal 7, one("select count(1) as cnt from visits_week where von between date_sub(curdate(), interval 7 day) and date_sub(curdate(), interval 1 day)")["cnt"].to_i
  end
  
  # should "handle today and day periods but nothing else" do
  # end
  
end
