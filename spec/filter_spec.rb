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

  context 'Lesser-or-equal filters' do
    it 'detects "equality"' do
      subject.run([:le, 'foo', nil, 'abc'], input).should be_true
    end

    it 'detects greater values' do
      subject.run([:le, 'foo', nil, 'a'], input).should be_false
    end

    it 'detects lesser values' do
      subject.run([:le, 'bar', nil, 'wibblespong2'], input).should be_true
    end

    it 'returns false for unknown attributes' do
      subject.run([:le, 'not_attr', nil, 'abc'], input).should be_false
    end
  end

  # RFC 4517
  # http://www.faqs.org/rfcs/rfc4517.html
  # 4.2.6
  context 'Substring filters with initial substrings only' do
    it 'finds initial substrings' do
      [
        subject.run([:substrings, 'foo', nil, 'a', nil], input),
        subject.run([:substrings, 'foo', nil, 'ab', nil], input),
        subject.run([:substrings, 'foo', nil, 'abc', nil], input),
        subject.run([:substrings, 'foo', nil, 'def', nil], input),
      ].reduce(:&).should be_true
    end
    it 'returns false when no substring matches' do
      [
        subject.run([:substrings, 'foo', nil, 'b', nil], input),
        subject.run([:substrings, 'foo', nil, 'bc', nil], input),
        subject.run([:substrings, 'foo', nil, 'ac', nil], input),
        subject.run([:substrings, 'foo', nil, 'bd', nil], input),
      ].reduce(:|).should be_false
    end
    it 'finds the empty initial string' do
      subject.run([:substrings, 'foo', nil, '', nil], input).should be_true
    end
    it 'returns false for unknown attributes' do
      [
        subject.run([:substrings, 'not_attr', nil, '', nil], input),
        subject.run([:substrings, 'not_attr', nil, 'abc', nil], input),
      ].reduce(:|).should be_false
    end
  end

  context 'Substring filters with initial and prepared substrings' do
    it 'finds substrings' do
      [
        subject.run([:substrings, 'foo', nil, '', 'a', nil], input),
        subject.run([:substrings, 'foo', nil, 'a', 'b', nil], input),
        subject.run([:substrings, 'foo', nil, 'ab', 'c', nil], input),
        subject.run([:substrings, 'foo', nil, 'abc', '', nil], input),
        subject.run([:substrings, 'foo', nil, 'd', '',  nil], input),
      ].reduce(:&).should be_true
    end
    it 'returns false when no substring matches' do
      [
        subject.run([:substrings, 'foo', nil, 'b', '', nil], input),
        subject.run([:substrings, 'foo', nil, 'b', 'c', nil], input),
        subject.run([:substrings, 'foo', nil, 'ac', nil], input),
      ].reduce(:|).should be_false
    end
    it 'finds the empty string' do
      subject.run([:substrings, 'foo', nil, '', '', nil], input).should be_true
    end
    it 'returns false for unknown attributes' do
      [
        subject.run([:substrings, 'not_attr', nil, '', '', nil], input),
        subject.run([:substrings, 'not_attr', nil, '', 'abc', nil], input),
        subject.run([:substrings, 'not_attr', nil, 'abc', '', nil], input),
        subject.run([:substrings, 'not_attr', nil, 'a', 'b', nil], input),
      ].reduce(:|).should be_false
    end
  end

  context 'Substring filters with final substring only' do
    it 'finds substrings' do
      [
        subject.run([:substrings, 'foo', nil, nil, 'c'], input),
        subject.run([:substrings, 'foo', nil, nil, 'bc'], input),
        subject.run([:substrings, 'foo', nil, nil, 'abc'], input),
      ].reduce(:&).should be_true
    end
    it 'returns false when no substring matches' do
      subject.run([:substrings, 'foo', nil, nil, 'd'], input).should be_false
    end
    it 'finds the empty string' do
      subject.run([:substrings, 'foo', nil, nil, ''], input).should be_true
    end
    it 'returns false for unknown attributes' do
      [
        subject.run([:substrings, 'not_attr', nil, nil, ''], input),
        subject.run([:substrings, 'not_attr', nil, nil, 'c'], input),
        subject.run([:substrings, 'not_attr', nil, nil, 'bc'], input),
        subject.run([:substrings, 'not_attr', nil, nil, 'abc'], input),
        subject.run([:substrings, 'not_attr', nil, nil, '0abc'], input),
      ].reduce(:|).should be_false
    end
  end

  context 'Substring filters with final and prepared substrings' do
    it 'finds substrings' do
      [
        subject.run([:substrings, 'foo', nil, nil, '', 'c'], input),
        subject.run([:substrings, 'foo', nil, nil, 'b', 'c'], input),
        subject.run([:substrings, 'foo', nil, nil, 'ab', 'c'], input),
      ].reduce(:&).should be_true
    end
    it 'returns false when no substring matches' do
      [
        subject.run([:substrings, 'foo', nil, nil, 'b', 'd'], input),
        subject.run([:substrings, 'foo', nil, nil, 'ab', 'd'], input),
        subject.run([:substrings, 'foo', nil, nil, 'abc', 'd'], input),
      ].reduce(:|).should be_false
    end
    it 'finds the empty string' do
      subject.run([:substrings, 'foo', nil, nil, '', ''], input).should be_true
    end
    it 'returns false for unknown attributes' do
      [
        subject.run([:substrings, 'not_attr', nil, nil, '', ''], input),
        subject.run([:substrings, 'not_attr', nil, nil, '', 'abc'], input),
        subject.run([:substrings, 'not_attr', nil, nil, 'abc', ''], input),
        subject.run([:substrings, 'not_attr', nil, nil, 'b', 'c'], input),
      ].reduce(:|).should be_false
    end
  end

  context 'Substring filters with initial, final, and prepared substrings' do
    it 'finds substrings' do
      [
        subject.run([:substrings, 'foo', nil, 'a', '', 'c'], input),
        subject.run([:substrings, 'foo', nil, 'a', 'b', 'c'], input),
        subject.run([:substrings, 'foo', nil, '', 'ab', 'c'], input),
        subject.run([:substrings, 'foo', nil, 'a', 'b', ''], input),
      ].reduce(:&).should be_true
    end
    it 'returns false when no substring matches' do
      [
        subject.run([:substrings, 'foo', nil, 'x', 'b', 'c'], input),
        subject.run([:substrings, 'foo', nil, 'a', 'x', 'c'], input),
        subject.run([:substrings, 'foo', nil, 'a', 'b', 'x'], input),
      ].reduce(:|).should be_false
    end
    it 'finds the empty string' do
      subject.run([:substrings, 'foo', nil, '', '', ''], input).should be_true
    end
    it 'returns false for unknown attributes' do
      [
        subject.run([:substrings, 'not_attr', nil, '', '', ''], input),
        subject.run([:substrings, 'not_attr', nil, '', '', 'abc'], input),
        subject.run([:substrings, 'not_attr', nil, '', 'abc', ''], input),
        subject.run([:substrings, 'not_attr', nil, 'abc', 'abc', ''], input),
        subject.run([:substrings, 'not_attr', nil, 'a', 'b', 'c'], input),
      ].reduce(:|).should be_false
    end
  end

  # RFC 4517
  # http://www.faqs.org/rfcs/rfc4517.html
  # 4.2.8
  context 'Substring filters for case insensitive IA5 strings' do
    let :rule do
      LDAP::Server::MatchingRule.find('caseIgnoreIA5SubstringsMatch')
    end
    it 'finds initial substrings' do
      [
        subject.run([:substrings, 'foo', rule, 'a', nil], input),
        subject.run([:substrings, 'foo', rule, 'A', nil], input),
        subject.run([:substrings, 'foo', rule, 'ab', nil], input),
        subject.run([:substrings, 'foo', rule, 'AB', nil], input),
        subject.run([:substrings, 'foo', rule, 'aB', nil], input),
        subject.run([:substrings, 'foo', rule, 'Ab', nil], input),
        subject.run([:substrings, 'foo', rule, 'a', 'b', nil], input),
        subject.run([:substrings, 'foo', rule, 'A', 'b', nil], input),
        subject.run([:substrings, 'foo', rule, 'a', 'B', nil], input),
        subject.run([:substrings, 'foo', rule, 'A', 'B', nil], input),
        subject.run([:substrings, 'foo', rule, 'a', 'b', 'c'], input),
        subject.run([:substrings, 'foo', rule, 'A', 'b', 'c'], input),
        subject.run([:substrings, 'foo', rule, 'A', 'B', 'c'], input),
        subject.run([:substrings, 'foo', rule, 'A', 'B', 'C'], input),
        subject.run([:substrings, 'foo', rule, 'a', 'B', 'C'], input),
        subject.run([:substrings, 'foo', rule, 'a', 'b', 'C'], input),
        subject.run([:substrings, 'foo', rule, 'a', 'B', 'c'], input),
        subject.run([:substrings, 'foo', rule, 'def', nil], input),
        subject.run([:substrings, 'foo', rule, 'dEf', nil], input),
      ].reduce(:&).should be_true
    end
    it 'returns false when no substring matches' do
      [
        subject.run([:substrings, 'foo', rule, 'b', nil], input),
        subject.run([:substrings, 'foo', rule, 'bc', nil], input),
        subject.run([:substrings, 'foo', rule, 'ac', nil], input),
        subject.run([:substrings, 'foo', rule, 'bd', nil], input),
      ].reduce(:|).should be_false
    end
    it 'finds the empty initial string' do
      subject.run([:substrings, 'foo', rule, '', '', ''], input).should be_true
    end
    it 'returns false for unknown attributes' do
      [
        subject.run([:substrings, 'not_attr', rule, '', nil], input),
        subject.run([:substrings, 'not_attr', rule, 'abc', nil], input),
      ].reduce(:|).should be_false
    end
  end

  context 'Filter conjunction' do
    it 'true & true' do
      subject.run([:and, [:true], [:true]], {}).should be_true
    end
    it 'true & false' do
      subject.run([:and, [:true], [:false]], {}).should be_false
    end
    it 'false & false' do
      subject.run([:and, [:false], [:false]], {}).should be_false
    end
    it 'false & true' do
      subject.run([:and, [:false], [:true]], {}).should be_false
    end
  end

  context 'Filter disjunction' do
    it 'true & true' do
      subject.run([:or, [:true], [:true]], {}).should be_true
    end
    it 'true & false' do
      subject.run([:or, [:true], [:false]], {}).should be_true
    end
    it 'false & false' do
      subject.run([:or, [:false], [:false]], {}).should be_false
    end
    it 'false & true' do
      subject.run([:or, [:false], [:true]], {}).should be_true
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

    it 'negates substrings filters' do
      subject.run([:not, [:substrings, 'foo', nil, 'a', 'b', 'c']], input).should be_false
    end

    it 'negates and filter operators' do
      subject.run([:not, [:and, [:true], [:true]]], input).should be_false
    end

    it 'negates or filter operators' do
      subject.run([:not, [:or, [:true], [:true]]], input).should be_false
    end
  end

end

