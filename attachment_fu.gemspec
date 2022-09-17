# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name			  = %q{attachment_fu}
  s.authors			  = ["Rick Olson", "Steven Pothoven", "Bang Ly"]
  s.summary			  = %q{attachment_fu as a gem}
  s.description		  = %q{This is a fork of Rick Olson's attachment_fu adding Ruby 1.9 and Rails 3.2 and Rails 4 to Rails 7 support as well as some other enhancements.}
  s.email			  = %q{lytieubang@yahoo.com}
  s.homepage		  = %q{http://github.com/tbly/attachment_fu}
  s.version			  = "3.3.3.5"
  s.date			  = %q{2022-09-17}

  s.files			  = Dir.glob("{lib,vendor}/**/*") + %w( CHANGELOG LICENSE README.rdoc amazon_s3.yml.tpl rackspace_cloudfiles.yml.tpl )
  s.extra_rdoc_files  = ["README.rdoc"]
  s.rdoc_options	  = ["--inline-source", "--charset=UTF-8"]
  s.require_paths	  = ["lib"]
  s.rubyforge_project = "nowarning"
  s.rubygems_version  = %q{1.8.29}

  s.requirements << 'aws-sdk-v1, ~> 1.61.0'

  if s.respond_to? :specification_version then
    s.specification_version = 2
  end
end
