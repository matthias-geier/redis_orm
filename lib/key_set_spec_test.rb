gem 'minitest'

require 'redis'
require 'minitest/autorun'
require './moo_redis/extensions/string'
require './moo_redis/database'
require './moo_redis/transformations'
require './moo_redis/key_value'
require './moo_redis/key_set'

class Donkey < MooRedis::KeySet
end

MooRedis::Database.create

describe Donkey do
  before do
    @donkey = Donkey.new
  end

  after do
    @donkey = nil
  end

  it "should find the object in the database and create initialize" do
    @donkey.update_data('25', 'franz')
    @donkey.save

    loaded_Donkey = Donkey.find("25")
    assert_equal @donkey, loaded_Donkey
    @donkey.destroy
  end

  it "should return nil when no object with that id is found" do
    assert_nil Donkey.find("30")
  end

  it "should initialize with empty set" do
    assert_equal([], @donkey)
  end

  it "should implement eql? and == and compare internal sorted arrays" do
    cmp = ['franz']
    @donkey.update_data('25', cmp)
    assert @donkey == cmp
    assert @donkey.eql?(cmp)
  end

  it "should implement empty? like an array" do
    assert @donkey.empty?
    @donkey.update_data('25', 'franz')
    refute @donkey.empty?
  end

  it "should behave like an array on inspect and to_s" do
    cmp = ['franz']
    @donkey.update_data('25', cmp)
    assert_equal cmp.inspect, @donkey.inspect
    assert_equal cmp.to_s, @donkey.to_s
  end

  it "should multiassign values with update_fields by automatism" do
    fields = ['name', 'email', 'created_at']
    @donkey.update_data('25', *fields)

    fields.each{ |f| assert @donkey.value.include?(f) }
  end

  describe "with set fields" do
    before do
      @donkey.update_data("klaus", "a@b.c", "kurz")
      if MooRedis::Database.db.exists("donkey:klaus")
        MooRedis::Database.db.del("donkey:klaus")
      end
    end

    after do
      @donkey.update_data('', [])
      if MooRedis::Database.db.exists("donkey:klaus")
        MooRedis::Database.db.del("donkey:klaus")
      end
    end

    it "should save to database" do
      @donkey.save
      saved_data = MooRedis::Transformations.transform("donkey:klaus")
      assert_equal @donkey, saved_data
    end

    it "should reload from the database" do
      @donkey.save
      data = @donkey.to_a
      @donkey.update_data(nil, 'franz')
      refute_equal data, @donkey
      @donkey.load
      assert_equal data, @donkey
    end

    it "should destroy the record in the database" do
      @donkey.save
      @donkey.destroy
      assert_nil Donkey.find(@donkey.id)
    end
  end
end
