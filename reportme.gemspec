# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{reportme}
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jan Zimmek"]
  s.date = %q{2009-06-23}
  s.description = %q{ReportMe is a thin ruby wrapper around your reporting sql queries which empowers you to automate, historicize, graph and mail them in an easy manner.}
  s.email = %q{jan.zimmek@web.de}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/reportme.rb",
     "lib/reportme/report.rb",
     "lib/reportme/report_factory.rb",
     "test/report_me_test.rb",
     "test/test_helper.rb"
  ]
  s.homepage = %q{http://github.com/jzimmek/report_me}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Ruby wrapper to automate sql reports}
  s.test_files = [
    "test/report_me_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
