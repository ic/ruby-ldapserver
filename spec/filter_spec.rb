require 'ldap/server/filter'

describe LDAP::Server::Filter do

  subject { LDAP::Server::Filter }

  context 'Simple filters' do
  end

  context 'Edge-case filters' do

    it 'returns true for a "true" filter' do
      subject.run([:true], {}).should be_true
    end

    it 'returns false for a "false" filter' do
      subject.run([:false], {}).should be_false
    end

  end

end

