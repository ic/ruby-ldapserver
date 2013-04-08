require 'ldap/server'
require 'thread'
require 'resolv-replace'	# ruby threading DNS client

# An example of an LDAP to SQL gateway. We have a MySQL table which
# contains (login_id,login,passwd) combinations, e.g.
#
#   +----------+----------+--------+
#   | login_id | login    | passwd |
#   +----------+----------+--------+
#   |    1     | brian    | foobar |
#   |    2     | caroline | boing  |
#   +----------+----------+--------+
#
# We support LDAP searches for (uid=login), returning a synthesised DN and
# Maildir attribute, and we support LDAP binds to validate passwords. We
# keep a cache of recent lookups so that a bind to validate a password
# doesn't cause a second SQL query. Since we're multi-threaded, this should
# work even if the bind occurs on a different client connection to the search.
#
# To test:
#    ldapsearch -H ldap://127.0.0.1:1389/ -b "dc=example,dc=com" "(uid=brian)"
#
#    ldapsearch -H ldap://127.0.0.1:1389/ -b "dc=example,dc=com" \
#       -D "id=1,dc=example,dc=com" -W "(uid=brian)"

TABLE = "logins"
SQL_POOL_SIZE = 5
PW_CACHE_SIZE = 100
BASEDN = "dc=example,dc=com"
LDAP_PORT = 1389

class SQLOperation < LDAP::Server::Operation
  # Handle searches of the form "(uid=<foo>)" using SQL backend
  # (uid=foo) => [:eq, "uid", matchobj, "foo"]
  def search(basedn, scope, deref, filter)
require 'debugger'; debugger
    raise LDAP::ResultError::UnwillingToPerform, "Bad base DN" unless basedn == BASEDN
    raise LDAP::ResultError::UnwillingToPerform, "Bad filter" unless filter[0..1] == [:eq, "uid"]
    uid = filter[3]
    res = Logins.all(uid)
    res.each do |login|
      send_SearchResultEntry("id=#{login.login_id},#{BASEDN}", {
        "maildir" => [ "/netapp/#{uid}/" ],
      })
    end
  end

  # Validate passwords
  def simple_bind(version, dn, password)
require 'debugger'; debugger
    return if dn.nil?   # accept anonymous
    raise LDAP::ResultError::UnwillingToPerform unless dn =~ /\Aid=(\d+),#{BASEDN}\z/
    login_id = $1
    login = Logins.get(login_id)
    raise LDAP::ResultError::InvalidCredentials unless login.password == password
  end
end

s = LDAP::Server.new(
	port:    LDAP_PORT,
	nodelay: true,
	listen:  10,
#	:ssl_key_file		=> "key.pem",
#	:ssl_cert_file		=> "cert.pem",
#	:ssl_on_connect		=> true,
	operation_class: SQLOperation
)

# Register for normal exits.
Signal.trap('INT') do
  exit 0
end

# Start the server and wait for an interrupt to finish.
s.run_tcpserver
s.join

