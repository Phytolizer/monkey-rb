# frozen_string_literal: true

require_relative 'object'
require 'test/unit'

## Tests that are directly for Monkey's object system.
class TestObject < Test::Unit::TestCase
  def test_string_hash_key
    hello1 = MonkeyString.new('Hello World')
    hello2 = MonkeyString.new('Hello World')
    diff1 = MonkeyString.new('My name is johnny')
    diff2 = MonkeyString.new('My name is johnny')

    assert_equal(hello1.hash_key, hello2.hash_key)
    assert_equal(diff1.hash_key, diff2.hash_key)
    assert_not_equal(hello1.hash_key, diff1.hash_key)
  end
end
