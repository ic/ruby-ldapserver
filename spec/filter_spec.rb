require 'ldap/server/filter'

describe LDAP::Server::Filter do

  #
  # Filters are executed with the ::run method, so
  #   the subject must be the class, not an instance.
  #
  subject { LDAP::Server::Filter }

  let :input do
    {
      'foo' => [ 'abc', 'def' ],
      'bar' => [ 'wibblespong' ],
    }
  end

  context 'Simple filters' do

    it 'should '

  end

  context 'Bad filters' do

    it 'raises an operation error for unknown filter types' do
      expect {
        subject.run([:whatever], {})
      }.to raise_error(LDAP::ResultError::OperationsError)
    end

  end

  context 'Edge-case filters' do

    it 'returns true for a "true" filter' do
      subject.run([:true], {}).should be_true
    end

    it 'returns false for a "false" filter' do
      subject.run([:false], {}).should be_false
    end

    it 'returns nil for a "undef" filter' do
      subject.run([:undef], {}).should be_nil
    end

  end

end

