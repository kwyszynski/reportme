require 'rubygems'
require 'activerecord'
require "actionmailer"

class Object
  
  def self.dsl_attr(name, opts={})

    self.class.send(:define_method, name) do |value|
      key = "@@#{name}".to_sym
      class_variable_set(key, value)
    end

    self.class.send(:define_method, "#{name}_value".to_sym) do
      class_variable_get("@@#{name}".to_sym)
    end

    self.class.send(:define_method, "#{name}_reset".to_sym) do
      default = opts[:default].try(:call)
      class_variable_set("@@#{name}".to_sym, default)
    end

    default = opts[:default].try(:call)
    send(name, default)

  end
  
end

require 'reportme/report_factory'

