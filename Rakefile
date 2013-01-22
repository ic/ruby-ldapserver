require 'rubygems'
require 'hoe'
require File.join(File.dirname(__FILE__), 'lib', 'ldap', 'server', 'version')

RDOC_OPTS = ['--quiet', '--title', 'ruby-ldapserver',
    '--opname', 'index.html',
    '--line-numbers', 
    '--main', 'README',
    '--inline-source']

# Generate all the Rake tasks
Hoe.spec 'ruby-ldapserver' do |p|
  p.rubyforge_name = 'ruby-ldapserver'
  p.version = LDAP::Server::VERSION
  p.summary = 'A pure-Ruby framework for building LDAP servers'
  p.description = 'ruby-ldapserver is a lightweight, pure-Ruby skeleton for implementing LDAP server applications.'
  p.author = 'Brian Candler'
  p.email = 'B.Candler@pobox.com'
  p.urls = { home: 'http://rubyforge.org/projects/ruby-ldapserver' }
  p.test_globs = [ 'test/**/*_test.rb' ]
  p.changes = p.paragraphs_of('ChangeLog', 0..1).join("\n\n")
end
