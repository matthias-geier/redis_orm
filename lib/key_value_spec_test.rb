gem 'minitest'

require 'redis'
require 'minitest/autorun'
require './moo_redis/extensions/string'
require './moo_redis/database'
require './moo_redis/transformations'
require './moo_redis/key_value'
require './moo_redis/key_array'
require './moo_redis/key_hash'

class Mule < MooRedis::KeyValue
end

MooRedis::Database.create

describe Mule do
  before do
    @mule = Mule.new
  end

  after do
    @mule = nil
  end

  it "should find the object in the database and create initialize" do
    @mule.update_data("25", "30")
    @mule.save

    loaded_mule = Mule.find("25")
    assert_equal @mule, loaded_mule
    @mule.destroy
  end

  it "should return nil when no object with that id is found" do
    assert_nil Mule.find("30")
  end

  it "should initialize with empty string" do
    assert_equal "", @mule
  end

  it "should implement empty? on the internal string" do
    assert @mule.empty?
    @mule.value = 'foo'
    refute @mule.empty?
  end

  it "should implement eql? and == and compare internal strings" do
    value = 'foo'
    @mule.value = value
    assert @mule == value
    assert @mule.eql?(value)
    assert_equal value, @mule.value
  end

  it "should behave like a string on inspect and to_s" do
    value = 'foo'
    @mule.value = value
    assert_equal value.inspect, @mule.inspect
    assert_equal value.to_s, @mule.to_s
  end

  it "should set autosave initially through constructor" do
    u = Mule.new(true, 'foo')
    assert u.autosave?
    u = Mule.new(false, 'foo')
    refute u.autosave?
    assert u.destroy
  end

  it "should update autosave" do
    @mule.autosave = true
    assert @mule.autosave?
    @mule.autosave = false
    refute @mule.autosave?
  end

  describe "with set fields" do
    before do
      @mule.update_data('klaus', 'cool')
      if MooRedis::Database.db.exists("mule:klaus")
        MooRedis::Database.db.del("mule:klaus")
      end
    end

    after do
      @mule.update_data(nil, nil)
      if MooRedis::Database.db.exists("mule:klaus")
        MooRedis::Database.db.del("mule:klaus")
      end
    end

    it "should save to database" do
      @mule.save
      saved_data = MooRedis::Transformations.transform("mule:klaus")
      assert_equal @mule, saved_data
    end

    it "should reload from the database" do
      @mule.save
      data = @mule.to_s
      @mule.update_data(nil, 'franz')
      refute_equal data, @mule
      @mule.load
      assert_equal data, @mule
    end

    it "should destroy the database entry" do
      @mule.save
      @mule.destroy
      assert_nil Mule.find(@mule.id)
    end
  end
end
