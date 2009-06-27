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

  class TestReport < Reportme::ReportFactory
  end
  
  def create_visit_report_factory(opts={})
    
    defaults = {
      :periods => [],
      :init => lambda {}
    }
    
    opts = defaults.merge(opts)
    
    TestReport.connection :adapter => "mysql", :database => "report_me_test", :username => "root", :password => "root", :host => "localhost", :port => 3306
    TestReport.init do
      opts[:init].call
    end
    TestReport.report :visits do
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
    
    @rme = TestReport.new
    
  end
  
  def exec(sql)
    puts "exec: #{sql}"
    ActiveRecord::Base.connection.execute(sql)
  end

  def one(sql)
    puts "one: #{sql}"
    ActiveRecord::Base.connection.select_one(sql)
  end

  def teardown
    unless @debug
      exec("drop table if exists report_informations;")
    
      [:today, :day, :week, :calendar_week, :month, :calendar_month].each do |period|
      
        TestReport.reports_value.each do |report|
          exec("drop table if exists #{report.table_name(period)};")
        end
      end
    
      TestReport.reports_reset
      TestReport.init_reset
      TestReport.subscribtions_reset
      TestReport.properties_reset

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
  
    # @debug = true
  
    #should be ignored
    exec("insert into visits values (null, 'sem', curdate());");
  
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 1 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 2 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 3 day));");
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 4 day));");
  
    # should be ignored
    exec("insert into visits values (null, 'sem', date_sub(curdate(), interval 5 day));");
  
    create_visit_report_factory(:periods => [:day]).run(3.days.ago)
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
  
    create_visit_report_factory(:periods => [:day]).run(10.days.ago)
    
    exec("truncate visits;")
  
    Reportme::ReportFactory.init_reset
  
    create_visit_report_factory(:periods => [:week]).run
  
    assert_equal 7, one("select count(1) as cnt from visits_week where date(von) between date_sub(curdate(), interval 7 day) and date_sub(curdate(), interval 1 day)")["cnt"].to_i
  end
  
  should "generate the von/bis range for the periods" do
  
    ##
    # anfang monat - 30 tage
    ##
    
    periods = {}
    Reportme::ReportFactory.periods('2009-06-01'.to_date).each{|p| periods[p[:name]] = p}
    
    # assert_equal '2009-06-01 00:00:00'.to_datetime, periods[:today][:von]
    # assert_equal '2009-06-01 23:59:59'.to_datetime, periods[:today][:bis]
    
    assert_equal '2009-05-31 00:00:00'.to_datetime, periods[:day][:von]
    assert_equal '2009-05-31 23:59:59'.to_datetime, periods[:day][:bis]
    
    assert_equal '2009-05-25 00:00:00'.to_datetime, periods[:week][:von]
    assert_equal '2009-05-31 23:59:59'.to_datetime, periods[:week][:bis]
    
    assert_equal '2009-05-25 00:00:00'.to_datetime, periods[:calendar_week][:von]
    assert_equal '2009-05-31 23:59:59'.to_datetime, periods[:calendar_week][:bis]
  
    assert_equal '2009-05-01 00:00:00'.to_datetime, periods[:month][:von]
    assert_equal '2009-05-31 23:59:59'.to_datetime, periods[:month][:bis]
  
    assert_equal '2009-05-01 00:00:00'.to_datetime, periods[:calendar_month][:von]
    assert_equal '2009-05-31 23:59:59'.to_datetime, periods[:calendar_month][:bis]
    
    
    ##
    # mitten monat - 30 tage
    ##
    
    periods.clear
    Reportme::ReportFactory.periods('2009-06-24'.to_date).each{|p| periods[p[:name]] = p}
    
    # assert_equal '2009-06-24 00:00:00'.to_datetime, periods[:today][:von]
    # assert_equal '2009-06-24 23:59:59'.to_datetime, periods[:today][:bis]
    
    assert_equal '2009-06-23 00:00:00'.to_datetime, periods[:day][:von]
    assert_equal '2009-06-23 23:59:59'.to_datetime, periods[:day][:bis]
    
    assert_equal '2009-06-17 00:00:00'.to_datetime, periods[:week][:von]
    assert_equal '2009-06-23 23:59:59'.to_datetime, periods[:week][:bis]
    
    assert_equal '2009-06-15 00:00:00'.to_datetime, periods[:calendar_week][:von]
    assert_equal '2009-06-21 23:59:59'.to_datetime, periods[:calendar_week][:bis]
  
    assert_equal '2009-05-24 00:00:00'.to_datetime, periods[:month][:von]
    assert_equal '2009-06-23 23:59:59'.to_datetime, periods[:month][:bis]
  
    assert_equal '2009-05-01 00:00:00'.to_datetime, periods[:calendar_month][:von]
    assert_equal '2009-05-31 23:59:59'.to_datetime, periods[:calendar_month][:bis]
  
    ##
    # ende monat - 30 tage
    ##
    
    periods.clear
    Reportme::ReportFactory.periods('2009-06-30'.to_date).each{|p| periods[p[:name]] = p}
    
    # assert_equal '2009-06-30 00:00:00'.to_datetime, periods[:today][:von]
    # assert_equal '2009-06-30 23:59:59'.to_datetime, periods[:today][:bis]
    
    assert_equal '2009-06-29 00:00:00'.to_datetime, periods[:day][:von]
    assert_equal '2009-06-29 23:59:59'.to_datetime, periods[:day][:bis]
    
    assert_equal '2009-06-23 00:00:00'.to_datetime, periods[:week][:von]
    assert_equal '2009-06-29 23:59:59'.to_datetime, periods[:week][:bis]
    
    assert_equal '2009-06-22 00:00:00'.to_datetime, periods[:calendar_week][:von]
    assert_equal '2009-06-28 23:59:59'.to_datetime, periods[:calendar_week][:bis]
  
    assert_equal '2009-05-30 00:00:00'.to_datetime, periods[:month][:von]
    assert_equal '2009-06-29 23:59:59'.to_datetime, periods[:month][:bis]
  
    assert_equal '2009-05-01 00:00:00'.to_datetime, periods[:calendar_month][:von]
    assert_equal '2009-05-31 23:59:59'.to_datetime, periods[:calendar_month][:bis]
  
    ##
    # anfang monat - 31 tage
    ##
    
    periods.clear
    Reportme::ReportFactory.periods('2009-05-01'.to_date).each{|p| periods[p[:name]] = p}
    
    # assert_equal '2009-05-01 00:00:00'.to_datetime, periods[:today][:von]
    # assert_equal '2009-05-01 23:59:59'.to_datetime, periods[:today][:bis]
    
    assert_equal '2009-04-30 00:00:00'.to_datetime, periods[:day][:von]
    assert_equal '2009-04-30 23:59:59'.to_datetime, periods[:day][:bis]
    
    assert_equal '2009-04-24 00:00:00'.to_datetime, periods[:week][:von]
    assert_equal '2009-04-30 23:59:59'.to_datetime, periods[:week][:bis]
    
    assert_equal '2009-04-20 00:00:00'.to_datetime, periods[:calendar_week][:von]
    assert_equal '2009-04-26 23:59:59'.to_datetime, periods[:calendar_week][:bis]
  
    assert_equal '2009-03-31 00:00:00'.to_datetime, periods[:month][:von]
    assert_equal '2009-04-30 23:59:59'.to_datetime, periods[:month][:bis]
  
    assert_equal '2009-04-01 00:00:00'.to_datetime, periods[:calendar_month][:von]
    assert_equal '2009-04-30 23:59:59'.to_datetime, periods[:calendar_month][:bis]
  
    ##
    # mitte monat - 31 tage
    ##
    
    periods.clear
    Reportme::ReportFactory.periods('2009-05-15'.to_date).each{|p| periods[p[:name]] = p}
    
    # assert_equal '2009-05-15 00:00:00'.to_datetime, periods[:today][:von]
    # assert_equal '2009-05-15 23:59:59'.to_datetime, periods[:today][:bis]
    
    assert_equal '2009-05-14 00:00:00'.to_datetime, periods[:day][:von]
    assert_equal '2009-05-14 23:59:59'.to_datetime, periods[:day][:bis]
    
    assert_equal '2009-05-08 00:00:00'.to_datetime, periods[:week][:von]
    assert_equal '2009-05-14 23:59:59'.to_datetime, periods[:week][:bis]
    
    assert_equal '2009-05-04 00:00:00'.to_datetime, periods[:calendar_week][:von]
    assert_equal '2009-05-10 23:59:59'.to_datetime, periods[:calendar_week][:bis]
  
    assert_equal '2009-04-14 00:00:00'.to_datetime, periods[:month][:von]
    assert_equal '2009-05-14 23:59:59'.to_datetime, periods[:month][:bis]
  
    assert_equal '2009-04-01 00:00:00'.to_datetime, periods[:calendar_month][:von]
    assert_equal '2009-04-30 23:59:59'.to_datetime, periods[:calendar_month][:bis]
  
    ##
    # ende monat - 31 tage
    ##
    
    periods.clear
    Reportme::ReportFactory.periods('2009-05-31'.to_date).each{|p| periods[p[:name]] = p}
    
    # assert_equal '2009-05-31 00:00:00'.to_datetime, periods[:today][:von]
    # assert_equal '2009-05-31 23:59:59'.to_datetime, periods[:today][:bis]
    
    assert_equal '2009-05-30 00:00:00'.to_datetime, periods[:day][:von]
    assert_equal '2009-05-30 23:59:59'.to_datetime, periods[:day][:bis]
    
    assert_equal '2009-05-24 00:00:00'.to_datetime, periods[:week][:von]
    assert_equal '2009-05-30 23:59:59'.to_datetime, periods[:week][:bis]
    
    assert_equal '2009-05-18 00:00:00'.to_datetime, periods[:calendar_week][:von]
    assert_equal '2009-05-24 23:59:59'.to_datetime, periods[:calendar_week][:bis]
  
    assert_equal '2009-04-30 00:00:00'.to_datetime, periods[:month][:von]
    assert_equal '2009-05-30 23:59:59'.to_datetime, periods[:month][:bis]
  
    assert_equal '2009-04-01 00:00:00'.to_datetime, periods[:calendar_month][:von]
    assert_equal '2009-04-30 23:59:59'.to_datetime, periods[:calendar_month][:bis]
  
    ##
    # today
    ##
  
    periods.clear
    today = Date.today
    Reportme::ReportFactory.periods(today).each{|p| periods[p[:name]] = p}
    
    assert_equal "#{today.strftime('%Y-%m-%d')} 00:00:00".to_datetime, periods[:today][:von]
    assert_equal "#{today.strftime('%Y-%m-%d')} 23:59:59".to_datetime, periods[:today][:bis]
    
  end
  
  should "create the calendar_weekly report by using 7 daily reports" do
    
    today = '2009-06-24'
    
    # should be ignored in weekly
    exec("insert into visits values (null, 'sem', '#{today}');");
    # should be ignored in weekly
    exec("insert into visits values (null, 'sem', date_sub('#{today}', interval 1 day));");
    # should be ignored in weekly
    exec("insert into visits values (null, 'sem', date_sub('#{today}', interval 2 day));");
    exec("insert into visits values (null, 'sem', date_sub('#{today}', interval 3 day));");
    exec("insert into visits values (null, 'sem', date_sub('#{today}', interval 4 day));");
    exec("insert into visits values (null, 'sem', date_sub('#{today}', interval 5 day));");
    exec("insert into visits values (null, 'sem', date_sub('#{today}', interval 6 day));");
    exec("insert into visits values (null, 'sem', date_sub('#{today}', interval 7 day));");
    exec("insert into visits values (null, 'sem', date_sub('#{today}', interval 8 day));");
    exec("insert into visits values (null, 'sem', date_sub('#{today}', interval 9 day));");
    # should be ignored in weekly
    exec("insert into visits values (null, 'sem', date_sub('#{today}', interval 10 day));");
  
    create_visit_report_factory(:periods => [:day]).run(15.days.ago)
  
    exec("truncate visits;")
  
    Reportme::ReportFactory.init_reset
  
    create_visit_report_factory(:periods => [:calendar_week]).run
  
    assert_equal 7, one("select count(1) as cnt from visits_calendar_week where von between '2009-06-15 00:00:00' and '2009-06-21 00:00:00'")["cnt"].to_i
    
  end
  
  should "probe existing reports" do
    rme = create_visit_report_factory
    assert rme.class.has_report?(:visits)
    assert !rme.class.has_report?(:some_not_existing_report)
  end
  
  should "subscribe to visits report" do
    rme = create_visit_report_factory
    rme.class.subscribe :visits do
    end
    assert rme.class.has_subscribtion?(:visits)
  end
  
  should "fail on subscribtion to not existing report" do
    rme = create_visit_report_factory
    assert_raise RuntimeError do 
      rme.class.subscribe :some_not_existing_report do
      end
    end
  end
  
  should "notify subscriptions" do
    notifed = false
  
    rme = create_visit_report_factory
    rme.class.subscribe :visits do
      notifed = true
    end
    
    rme.class.notify_subscriber(:visits, :day, '2009-01-01'.to_datetime)
    
    assert notifed
  end
  
  should "call initializer before running reports" do
    initialized = false
  
    rme = create_visit_report_factory({
      :init => lambda {
        initialized = true
      }
    })
  
    rme.run
    
    assert initialized
    
  end
  
  should "fail when multiple init blocks are defined" do
  
    rme = create_visit_report_factory
    
    assert_raise RuntimeError do
      rme.class.init do
      end
    end
  end
  
end
