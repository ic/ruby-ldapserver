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

  context 'Present filters' do

    it 'should return true for existing entries' do
      subject.run([:present, 'foo'], input).should be_true
    end

    it 'should return false for missing entries' do
      subject.run([:present, 'foofoo'], input).should be_false
    end

  end

  context 'Wrong filters' do

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

  context 'Equality filters without matching rule' do

    it 'can match an existing attribute-value pair' do
      subject.run([:eq, 'foo', nil, 'abc'], input).should be_true
    end

    it 'can match several pairs in series' do
      first  = subject.run([:eq, 'foo', nil, 'abc'], input)
      second = subject.run([:eq, 'foo', nil, 'def'], input)
      (first && second).should be_true
    end

    it 'returns false when no value match is found' do
      subject.run([:eq, 'foo', nil, 'not_matched'], input).should be_false
    end

    it 'returns false when the attribute is not found' do
      subject.run([:eq, 'not_attr', nil, 'abc'], input).should be_false
    end

  end

  context 'Equality filters with the "caseIgnoreMatch" RFC matching rule' do

    # TODO Test other matching rules---untested in the original test suite.

    let :rule do
      LDAP::Server::MatchingRule.find('caseIgnoreMatch')
    end

    it 'can match exactly an existing attribute-value pair' do
      subject.run([:eq, 'foo', rule, 'abc'], input).should be_true
    end

    it 'can match an attribute-value pair despite different case' do
      subject.run([:eq, 'foo', rule, 'ABC'], input).should be_true
    end

    it 'can match exactly several pairs in series' do
      first  = subject.run([:eq, 'foo', nil, 'abc'], input)
      second = subject.run([:eq, 'foo', nil, 'def'], input)
      (first && second).should be_true
    end

    it 'can match several pairs in series despite different cases' do
      first  = subject.run([:eq, 'foo', rule, 'abC'], input)
      second = subject.run([:eq, 'foo', rule, 'dEf'], input)
      (first && second).should be_true
    end

    it 'returns false when no value match is found' do
      subject.run([:eq, 'foo', rule, 'not_matched'], input).should be_false
    end

    it 'returns false when the attribute is not found' do
      subject.run([:eq, 'not_attr', rule, 'abc'], input).should be_false
    end

  end

  context 'Greater-or-equal filters' do

    it 'detects "equality"' do
      subject.run([:ge, 'foo', nil, 'abc'], input).should be_true
    end

    it 'detects greater values' do
      subject.run([:ge, 'foo', nil, 'a'], input).should be_true
    end

    it 'detects lesser values' do
      subject.run([:ge, 'bar', nil, 'wibblespong2'], input).should be_false
    end

    it 'returns false for unknown attributes' do
      subject.run([:ge, 'not_attr', nil, 'abc'], input).should be_false
    end

  end

  context 'Negation filters' do
    it 'negates equality filters' do
      subject.run([:not, [:eq, 'foo', nil, 'abc']], input).should be_false
    end

    it 'negates presence filters' do
      subject.run([:not, [:present, 'foo']], input).should be_false
    end

    it 'negates true filters' do
      subject.run([:not, [:true]], input).should be_false
    end

    it 'negates false filters' do
      subject.run([:not, [:false]], input).should be_true
    end

    it 'negates undef filters' do
      subject.run([:not, [:undef]], input).should be_false
    end

    it 'negates greater-or-equal filters' do
      subject.run([:not, [:ge, 'foo', nil, 'abc']], input).should be_false
    end

    it 'negates lower-or-equal filters' do
      subject.run([:not, [:le, 'foo', nil, 'abc']], input).should be_false
    end

    it 'negates substrings filters'

    it 'negates and filter operators'

    it 'negates or filter operators'
  end

end

