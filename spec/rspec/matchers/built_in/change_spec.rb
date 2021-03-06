#Based on patch from Wilson Bilkovich

require 'spec_helper'

class SomethingExpected
  attr_accessor :some_value
end

describe "expect { ... }.to change(actual, message)" do
  context "with a numeric value" do
    before(:each) do
      @instance = SomethingExpected.new
      @instance.some_value = 5
    end

    it "passes when actual is modified by the block" do
      expect {@instance.some_value = 6.0}.to change(@instance, :some_value)
    end

    it "fails when actual is not modified by the block" do
      expect do
        expect {}.to change(@instance, :some_value)
      end.to fail_with("expected #some_value to have changed, but is still 5")
    end

    it "provides a #description" do
      expect(change(@instance, :some_value).description).to eq "change #some_value"
    end
  end

  it "can specify the change of a variable's class" do
    val = nil

    expect {
      val = 42
    }.to change { val.class }.from(NilClass).to(Fixnum)

    expect {
      expect {
        val = "string"
      }.to change { val.class }.from(Fixnum).to(NilClass)
    }.to fail_with(/but is now String/)
  end

  context "with boolean values" do
    before(:each) do
      @instance = SomethingExpected.new
      @instance.some_value = true
    end

    it "passes when actual is modified by the block" do
      expect {@instance.some_value = false}.to change(@instance, :some_value)
    end

    it "fails when actual is not modified by the block" do
      expect do
        expect {}.to change(@instance, :some_value)
      end.to fail_with("expected #some_value to have changed, but is still true")
    end
  end

  context "with nil value" do
    before(:each) do
      @instance = SomethingExpected.new
      @instance.some_value = nil
    end

    it "passes when actual is modified by the block" do
      expect {@instance.some_value = false}.to change(@instance, :some_value)
    end

    it "fails when actual is not modified by the block" do
      expect do
        expect {}.to change(@instance, :some_value)
      end.to fail_with("expected #some_value to have changed, but is still nil")
    end
  end

  context "with an array" do
    before(:each) do
      @instance = SomethingExpected.new
      @instance.some_value = []
    end

    it "passes when actual is modified by the block" do
      expect {@instance.some_value << 1}.to change(@instance, :some_value)
    end

    it "fails when a predicate on the actual fails" do
      expect do
        expect {@instance.some_value << 1}.to change { @instance.some_value }.to be_empty
      end.to fail_with(/result to have changed to/)
    end

    it "passes when a predicate on the actual passes" do
      @instance.some_value = [1]
      expect {@instance.some_value.pop}.to change { @instance.some_value }.to be_empty
    end

    it "fails when actual is not modified by the block" do
      expect do
        expect {}.to change(@instance, :some_value)
      end.to fail_with("expected #some_value to have changed, but is still []")
    end
  end

  context "with a hash" do
    before(:each) do
      @instance = SomethingExpected.new
      @instance.some_value = {:a => 'a'}
    end

    it "passes when actual is modified by the block" do
      expect {@instance.some_value[:a] = 'A'}.to change(@instance, :some_value)
    end

    it "fails when actual is not modified by the block" do
      expect do
        expect {}.to change(@instance, :some_value)
      end.to fail
    end
  end

  context "with a string" do
    it "passes when actual is modified by the block" do
      string = "ab"
      expect { string << "c" }.to change { string }
    end

    it 'fails when actual is not modified by the block' do
      string = "ab"
      expect {
        expect { }.to change { string }
      }.to fail_with(/to have changed/)
    end
  end

  context "with an arbitrary enumerable" do
    before(:each) do
      @instance = SomethingExpected.new
      @instance.some_value = Class.new do
        include Enumerable

        attr_reader :elements

        def initialize(*elements)
          @elements = elements.dup
        end

        def <<(element)
          elements << element
        end

        def dup
          self.class.new(*elements)
        end

        def ==(other)
          elements == other.elements
        end
      end.new
    end

    it "passes when actual is modified by the block" do
      expect {@instance.some_value << 1}.to change(@instance, :some_value)
    end

    it "fails when actual is not modified by the block" do
      expect do
        expect {}.to change(@instance, :some_value)
      end.to fail_with(/^expected #some_value to have changed, but is still/)
    end

  end
end

describe "expect { ... }.not_to change(actual, message)" do
  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when actual is not modified by the block" do
    expect { }.not_to change(@instance, :some_value)
  end

  it "fails when actual is not modified by the block" do
    expect do
      expect {@instance.some_value = 6}.not_to change(@instance, :some_value)
    end.to fail_with("expected #some_value not to have changed, but did change from 5 to 6")
  end
end

describe "expect { ... }.to change { block }" do

  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when actual is modified by the block" do
    expect {@instance.some_value = 6}.to change { @instance.some_value }
  end

  it "fails when actual is not modified by the block" do
    expect do
      expect {}.to change{ @instance.some_value }
    end.to fail_with("expected result to have changed, but is still 5")
  end

  it "warns if passed a block using do/end instead of {}" do
    expect do
      expect {}.to change do; end
    end.to raise_error(SyntaxError, /block passed to the `change` matcher/)
  end

  it "provides a #description" do
    expect(change { @instance.some_value }.description).to eq "change result"
  end
end

describe "expect { ... }.not_to change { block }" do
  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when actual is modified by the block" do
    expect {}.not_to change{ @instance.some_value }
  end

  it "fails when actual is not modified by the block" do
    expect do
      expect {@instance.some_value = 6}.not_to change { @instance.some_value }
    end.to fail_with("expected result not to have changed, but did change from 5 to 6")
  end

  it "warns if passed a block using do/end instead of {}" do
    expect do
      expect {}.not_to change do; end
    end.to raise_error(SyntaxError, /block passed to the `change` matcher/)
  end
end


describe "expect { ... }.not_to change { }.from" do
  context 'when the value starts at the from value' do
    it 'passes when the value does not change' do
      k = 5
      expect { }.not_to change { k }.from(5)
    end

    it 'fails when the value does change' do
      expect {
        k = 5
        expect { k += 1 }.not_to change { k }.from(5)
      }.to fail_with(/but did change from 5 to 6/)
    end
  end

  context 'when the value starts at a different value' do
    it 'fails when the value does not change' do
      expect {
        k = 6
        expect { }.not_to change { k }.from(5)
      }.to fail_with(/expected result to have initially been 5/)
    end

    it 'fails when the value does change' do
      expect {
        k = 6
        expect { k += 1 }.not_to change { k }.from(5)
      }.to fail_with(/expected result to have initially been 5/)
    end
  end
end

describe "expect { ... }.not_to change { }.to" do
  it 'is not supported' do
    expect {
      expect { }.not_to change { }.to(3)
    }.to raise_error(NotImplementedError)
  end

  it 'is not supported when it comes after `from`' do
    expect {
      expect { }.not_to change { }.from(nil).to(3)
    }.to raise_error(NotImplementedError)
  end
end

describe "expect { ... }.not_to change { }.by" do
  it 'is not supported' do
    expect {
      expect { }.not_to change { }.by(3)
    }.to raise_error(NotImplementedError)
  end
end

describe "expect { ... }.not_to change { }.by_at_least" do
  it 'is not supported' do
    expect {
      expect { }.not_to change { }.by_at_least(3)
    }.to raise_error(NotImplementedError)
  end
end

describe "expect { ... }.not_to change { }.by_at_most" do
  it 'is not supported' do
    expect {
      expect { }.not_to change { }.by_at_most(3)
    }.to raise_error(NotImplementedError)
  end
end

describe "expect { ... }.to change(actual, message).by(expected)" do
  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when attribute is changed by expected amount" do
    expect { @instance.some_value += 1 }.to change(@instance, :some_value).by(1)
  end

  it "passes when attribute is not changed and expected amount is 0" do
    expect { @instance.some_value += 0 }.to change(@instance, :some_value).by(0)
  end

  it "fails when the attribute is changed by unexpected amount" do
    expect do
      expect { @instance.some_value += 2 }.to change(@instance, :some_value).by(1)
    end.to fail_with("expected #some_value to have changed by 1, but was changed by 2")
  end

  it "fails when the attribute is changed by unexpected amount in the opposite direction" do
    expect do
      expect { @instance.some_value -= 1 }.to change(@instance, :some_value).by(1)
    end.to fail_with("expected #some_value to have changed by 1, but was changed by -1")
  end

  it "provides a #description" do
    expect(change(@instance, :some_value).by(3).description).to eq "change #some_value by 3"
  end
end

describe "expect { ... }.to change { block }.by(expected)" do
  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when attribute is changed by expected amount" do
    expect { @instance.some_value += 1 }.to change{@instance.some_value}.by(1)
  end

  it "fails when the attribute is changed by unexpected amount" do
    expect do
      expect { @instance.some_value += 2 }.to change{@instance.some_value}.by(1)
    end.to fail_with("expected result to have changed by 1, but was changed by 2")
  end

  it "fails when the attribute is changed by unexpected amount in the opposite direction" do
    expect do
      expect { @instance.some_value -= 1 }.to change{@instance.some_value}.by(1)
    end.to fail_with("expected result to have changed by 1, but was changed by -1")
  end

  it "provides a #description" do
    expect(change { @instance.some_value }.by(3).description).to eq "change result by 3"
  end
end

describe "expect { ... }.to change(actual, message).by_at_least(expected)" do
  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when attribute is changed by greater than the expected amount" do
    expect { @instance.some_value += 2 }.to change(@instance, :some_value).by_at_least(1)
  end

  it "passes when attribute is changed by the expected amount" do
    expect { @instance.some_value += 2 }.to change(@instance, :some_value).by_at_least(2)
  end

  it "fails when the attribute is changed by less than the expected amount" do
    expect do
      expect { @instance.some_value += 1 }.to change(@instance, :some_value).by_at_least(2)
    end.to fail_with("expected #some_value to have changed by at least 2, but was changed by 1")
  end

  it "provides a #description" do
    expect(change(@instance, :some_value).by_at_least(3).description).to eq "change #some_value by at least 3"
  end
end

describe "expect { ... }.to change { block }.by_at_least(expected)" do
  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when attribute is changed by greater than expected amount" do
    expect { @instance.some_value += 2 }.to change{@instance.some_value}.by_at_least(1)
  end

  it "passes when attribute is changed by the expected amount" do
    expect { @instance.some_value += 2 }.to change{@instance.some_value}.by_at_least(2)
  end

  it "fails when the attribute is changed by less than the unexpected amount" do
    expect do
      expect { @instance.some_value += 1 }.to change{@instance.some_value}.by_at_least(2)
    end.to fail_with("expected result to have changed by at least 2, but was changed by 1")
  end

  it "provides a #description" do
    expect(change { @instance.some_value }.by_at_least(3).description).to eq "change result by at least 3"
  end
end


describe "expect { ... }.to change(actual, message).by_at_most(expected)" do
  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when attribute is changed by less than the expected amount" do
    expect { @instance.some_value += 2 }.to change(@instance, :some_value).by_at_most(3)
  end

  it "passes when attribute is changed by the expected amount" do
    expect { @instance.some_value += 2 }.to change(@instance, :some_value).by_at_most(2)
  end

  it "fails when the attribute is changed by greater than the expected amount" do
    expect do
      expect { @instance.some_value += 2 }.to change(@instance, :some_value).by_at_most(1)
    end.to fail_with("expected #some_value to have changed by at most 1, but was changed by 2")
  end

  it "provides a #description" do
    expect(change(@instance, :some_value).by_at_most(3).description).to eq "change #some_value by at most 3"
  end
end

describe "expect { ... }.to change { block }.by_at_most(expected)" do
  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when attribute is changed by less than expected amount" do
    expect { @instance.some_value += 2 }.to change{@instance.some_value}.by_at_most(3)
  end

  it "passes when attribute is changed by the expected amount" do
    expect { @instance.some_value += 2 }.to change{@instance.some_value}.by_at_most(2)
  end

  it "fails when the attribute is changed by greater than the unexpected amount" do
    expect do
      expect { @instance.some_value += 2 }.to change{@instance.some_value}.by_at_most(1)
    end.to fail_with("expected result to have changed by at most 1, but was changed by 2")
  end

  it "provides a #description" do
    expect(change { @instance.some_value }.by_at_most(3).description).to eq "change result by at most 3"
  end
end

describe "expect { ... }.to change(actual, message).from(old)" do
  context "with boolean values" do
    before(:each) do
      @instance = SomethingExpected.new
      @instance.some_value = true
    end

    it "passes when attribute is == to expected value before executing block" do
      expect { @instance.some_value = false }.to change(@instance, :some_value).from(true)
    end

    it "fails when attribute is not == to expected value before executing block" do
      expect do
        expect { @instance.some_value = 'foo' }.to change(@instance, :some_value).from(false)
      end.to fail_with("expected #some_value to have initially been false, but was true")
    end
  end
  context "with non-boolean values" do
    before(:each) do
      @instance = SomethingExpected.new
      @instance.some_value = 'string'
    end

    it "passes when attribute is === to expected value before executing block" do
      expect { @instance.some_value = "astring" }.to change(@instance, :some_value).from("string")
    end

    it "compares the expected and actual values with ===" do
      expected = "string"
      expect(expected).to receive(:===).and_return true
      expect { @instance.some_value = "astring" }.to change(@instance, :some_value).from(expected)
    end

    it "fails when attribute is not === to expected value before executing block" do
      expect do
        expect { @instance.some_value = "knot" }.to change(@instance, :some_value).from("cat")
      end.to fail_with("expected #some_value to have initially been \"cat\", but was \"string\"")
    end

    it "provides a #description" do
      expect(change(@instance, :some_value).from(3).description).to eq "change #some_value from 3"
    end
  end
end

describe "expect { ... }.to change { block }.from(old)" do
  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 'string'
  end

  it "passes when attribute is === to expected value before executing block" do
    expect { @instance.some_value = "astring" }.to change{@instance.some_value}.from("string")
  end

  it "compares the expected and actual values with ===" do
    expected = "string"
    expect(expected).to receive(:===).and_return true
    expect { @instance.some_value = "astring" }.to change{@instance.some_value}.from(expected)
  end

  it "fails when attribute is not === to expected value before executing block" do
    expect do
      expect { @instance.some_value = "knot" }.to change{@instance.some_value}.from("cat")
    end.to fail_with("expected result to have initially been \"cat\", but was \"string\"")
  end

  it "provides a #description" do
    expect(change { }.from(3).description).to eq "change result from 3"
  end
end

describe "expect { ... }.to change(actual, message).to(new)" do
  context "with boolean values" do
    before(:each) do
      @instance = SomethingExpected.new
      @instance.some_value = true
    end

    it "passes when attribute is == to expected value after executing block" do
      expect { @instance.some_value = false }.to change(@instance, :some_value).to(false)
    end

    it "fails when attribute is not == to expected value after executing block" do
      expect do
        expect { @instance.some_value = 1 }.to change(@instance, :some_value).from(true).to(false)
      end.to fail_with("expected #some_value to have changed to false, but is now 1")
    end
  end
  context "with non-boolean values" do
    before(:each) do
      @instance = SomethingExpected.new
      @instance.some_value = 'string'
    end

    it "passes when attribute is === to expected value after executing block" do
      expect { @instance.some_value = "cat" }.to change(@instance, :some_value).to("cat")
    end

    it "compares the expected and actual values with ===" do
      expected = "cat"
      expect(expected).to receive(:===).and_return true
      expect { @instance.some_value = "cat" }.to change(@instance, :some_value).to(expected)
    end

    it "fails when attribute is not === to expected value after executing block" do
      expect do
        expect { @instance.some_value = "cat" }.to change(@instance, :some_value).from("string").to("dog")
      end.to fail_with("expected #some_value to have changed to \"dog\", but is now \"cat\"")
    end
  end
end

describe "expect { ... }.to change { block }.to(new)" do
  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 'string'
  end

  it "passes when attribute is === to expected value after executing block" do
    expect { @instance.some_value = "cat" }.to change{@instance.some_value}.to("cat")
  end

  it "compares the expected and actual values with ===" do
    expected = "cat"
    expect(expected).to receive(:===).and_return true
    expect { @instance.some_value = "cat" }.to change{@instance.some_value}.to(expected)
  end

  it "fails when attribute is not === to expected value after executing block" do
    expect do
      expect { @instance.some_value = "cat" }.to change{@instance.some_value}.from("string").to("dog")
    end.to fail_with("expected result to have changed to \"dog\", but is now \"cat\"")
  end

  it "provides a #description" do
    expect(change { }.to(3).description).to eq "change result to 3"
  end
end

describe "expect { ... }.to change(actual, message).from(old).to(new)" do
  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 'string'
  end

  it "passes when #to comes before #from" do
    expect { @instance.some_value = "cat" }.to change(@instance, :some_value).to("cat").from("string")
  end

  it "passes when #from comes before #to" do
    expect { @instance.some_value = "cat" }.to change(@instance, :some_value).from("string").to("cat")
  end

  it "shows the correct messaging when #after and #to are different" do
    expect do
      expect { @instance.some_value = "cat" }.to change(@instance, :some_value).from("string").to("dog")
    end.to fail_with("expected #some_value to have changed to \"dog\", but is now \"cat\"")
  end

  it "shows the correct messaging when #before and #from are different" do
    expect do
      expect { @instance.some_value = "cat" }.to change(@instance, :some_value).from("not_string").to("cat")
    end.to fail_with("expected #some_value to have initially been \"not_string\", but was \"string\"")
  end
end

describe "expect { ... }.to change { block }.from(old).to(new)" do
  before(:each) do
    @instance = SomethingExpected.new
    @instance.some_value = 'string'
  end

  context "when #to comes before #from" do
    it "passes" do
      expect { @instance.some_value = "cat" }.to change{@instance.some_value}.to("cat").from("string")
    end

    it "provides a #description" do
      expect(change { }.to(1).from(3).description).to eq "change result to 1 from 3"
    end
  end

  context "when #from comes before #to" do
    it "passes" do
      expect { @instance.some_value = "cat" }.to change{@instance.some_value}.from("string").to("cat")
    end

    it "provides a #description" do
      expect(change { }.from(1).to(3).description).to eq "change result from 1 to 3"
    end
  end
end

describe "Composing a matcher with `change`" do
  describe "expect { ... }.to change { ... }" do
    context ".from(matcher).to(matcher)" do
      it 'passes when the matchers match the from and to values' do
        k = 0.51
        expect { k += 1 }.to change { k }.
          from( a_value_within(0.1).of(0.5) ).
          to( a_value_within(0.1).of(1.5) )
      end

      it 'fails with a clear message when the `from` does not match' do
        expect {
          k = 0.51
          expect { k += 1 }.to change { k }.
            from( a_value_within(0.1).of(0.7) ).
            to( a_value_within(0.1).of(1.5) )
        }.to fail_with(/expected result to have initially been a value within 0.1 of 0.7, but was 0.51/)
      end

      it 'fails with a clear message when the `to` does not match' do
        expect {
          k = 0.51
          expect { k += 1 }.to change { k }.
            from( a_value_within(0.1).of(0.5) ).
            to( a_value_within(0.1).of(2.5) )
        }.to fail_with(/expected result to have changed to a value within 0.1 of 2.5, but is now 1.51/)
      end

      it 'provides a description' do
        expect(change(nil, :foo).
          from( a_value_within(0.1).of(0.5) ).
          to( a_value_within(0.1).of(1.5) ).description
        ).to eq("change #foo from a value within 0.1 of 0.5 to a value within 0.1 of 1.5")
      end
    end

    context ".to(matcher).from(matcher)" do
      it 'passes when the matchers match the from and to values' do
        k = 0.51
        expect { k += 1 }.to change { k }.
          to( a_value_within(0.1).of(1.5) ).
          from( a_value_within(0.1).of(0.5) )
      end

      it 'fails with a clear message when the `from` does not match' do
        expect {
          k = 0.51
          expect { k += 1 }.to change { k }.
            to( a_value_within(0.1).of(1.5) ).
            from( a_value_within(0.1).of(0.7) )
        }.to fail_with(/expected result to have initially been a value within 0.1 of 0.7, but was 0.51/)
      end

      it 'fails with a clear message when the `to` does not match' do
        expect {
          k = 0.51
          expect { k += 1 }.to change { k }.
            to( a_value_within(0.1).of(2.5) ).
            from( a_value_within(0.1).of(0.5) )
        }.to fail_with(/expected result to have changed to a value within 0.1 of 2.5, but is now 1.51/)
      end

      it 'provides a description' do
        expect(change(nil, :foo).
          to( a_value_within(0.1).of(0.5) ).
          from( a_value_within(0.1).of(1.5) ).description
        ).to eq("change #foo to a value within 0.1 of 0.5 from a value within 0.1 of 1.5")
      end
    end

    context ".by(matcher)" do
      it "passes when the matcher matches" do
        k = 0.5
        expect { k += 1.05 }.to change { k }.by( a_value_within(0.1).of(1) )
      end

      it 'fails with a clear message when the `by` does not match' do
        expect {
          k = 0.5
          expect { k += 1.05 }.to change { k }.by( a_value_within(0.1).of(0.5) )
        }.to fail_with(/expected result to have changed by a value within 0.1 of 0.5, but was changed by 1.05/)
      end

      it 'provides a description' do
        expect(change(nil, :foo).
          by( a_value_within(0.1).of(0.5) ).description
        ).to eq("change #foo by a value within 0.1 of 0.5")
      end
    end
  end

  describe "expect { ... }.not_to change { ... }.from(matcher).to(matcher)" do
    it 'passes when the matcher matches the `from` value and it does not change' do
      k = 0.51
      expect { }.not_to change { k }.from( a_value_within(0.1).of(0.5) )
    end

    it 'fails with a clear message when the `from` matcher does not match' do
      expect {
        k = 0.51
        expect { }.not_to change { k }.from( a_value_within(0.1).of(1.5) )
      }.to fail_with(/expected result to have initially been a value within 0.1 of 1.5, but was 0.51/)
    end
  end
end

describe RSpec::Matchers::BuiltIn::Change do
  it "works when the receiver has implemented #send" do
    @instance = SomethingExpected.new
    @instance.some_value = "string"
    def @instance.send(*args); raise "DOH! Library developers shouldn't use #send!" end

    expect {
      expect { @instance.some_value = "cat" }.to change(@instance, :some_value)
    }.not_to raise_error
  end

  k = 1
  before { k = 1 }
  it_behaves_like "an RSpec matcher", :valid_value => lambda { k += 1 },
                                      :invalid_value => lambda { } do
    let(:matcher) { change { k } }
  end
end

describe RSpec::Matchers::BuiltIn::ChangeRelatively do
  k = 0
  before { k = 0 }
  it_behaves_like "an RSpec matcher", :valid_value => lambda { k += 1 },
                                      :invalid_value => lambda { k += 2 } do
    let(:matcher) { change { k }.by(1) }
  end
end

describe RSpec::Matchers::BuiltIn::ChangeFromValue do
  k = 0
  before { k = 0 }
  it_behaves_like "an RSpec matcher", :valid_value => lambda { k += 1 },
                                      :invalid_value => lambda { } do
    let(:matcher) { change { k }.from(0) }
  end
end

describe RSpec::Matchers::BuiltIn::ChangeToValue do
  k = 0
  before { k = 0 }
  it_behaves_like "an RSpec matcher", :valid_value => lambda { k = 2 },
                                      :invalid_value => lambda { k = 3 } do
    let(:matcher) { change { k }.to(2) }
  end
end
