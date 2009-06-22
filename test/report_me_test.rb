require 'test_helper'

class ReportMeTest < Test::Unit::TestCase

  def setup
    
    ActiveRecord::Base.connection.execute "drop table if exists employees"
    ActiveRecord::Base.connection.execute <<-SQL
      create
        table employees
        (
          id bigint auto_increment,
          name varchar(255),
          age bigint,
          created_at datetime,
          primary key (id)
        )
    SQL
  end
  
  def create_employee_report_factory
    
    ReportMe::ReportFactory.create do
      report :employees do
        source do |von, bis|
          <<-SQL
          select
            date(created_at) as datum,
            count(1) as anzahl
          from
            employees
          where
            created_at between '#{von}' and '#{bis}'
          group by
            date(created_at)
          SQL
        end
      end
    end
        
    ActiveRecord::Base.connection.execute "truncate #{f.table_name(:number_of_employees)}"
  end
  

  should "probably rename this file and start testing for real" do
  end
end
