require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'report_me'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))


class Test::Unit::TestCase
end

ActiveRecord::Base.establish_connection(:adapter => "mysql", :database => "mysql", :username => "root", :password => "root", :host => "localhost", :port => 3306)

ActiveRecord::Base.connection.execute "drop database if exists report_me_test;"
ActiveRecord::Base.connection.execute "create database report_me_test;"
ActiveRecord::Base.connection.execute "use report_me_test;"