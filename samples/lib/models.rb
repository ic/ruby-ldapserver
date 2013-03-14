class Logins

  include DataMapper::Resource

  property :login_id, Serial
  property :login, String
  property :passwd, String

end

