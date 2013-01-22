require File.expand_path(File.join('..', 'lib', 'ldap', 'server', 'version'), __FILE__)

Gem::Specification.new do |s|
  s.name                      = 'ruby-ldapserver'
  s.version                   = LDAP::Server::VERSION
  s.platform                  = Gem::Platform::RUBY
  s.authors                   = [ 'Brian Candler' ]
  s.email                     = [ 'b.candler@pobox.com' ]
  s.summary                   = 'A pure-Ruby framework for building LDAP servers'
  s.homepage                  = 'http://rubyforge.org/projects/ruby-ldapserver'
  s.description               = 'ruby-ldapserver is a lightweight, pure-Ruby skeleton for implementing LDAP server applications.'
  s.required_rubygems_version = '~> 1.8.23'
  s.rubyforge_project         = 'ruby-ldapserver'
  s.files                     = Dir["lib/**/*.rb", "bin/*", "LICENSE", "*.md", "db/**/*.*"]
  s.require_paths             = ['lib']
end

