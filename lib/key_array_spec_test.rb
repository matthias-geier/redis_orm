gem 'minitest'

require 'redis'
require 'minitest/autorun'
require './moo_redis/extensions/string'
require './moo_redis/database'
require './moo_redis/transformations'
require './moo_redis/key_value'
require './moo_redis/key_array'

class Monkey < MooRedis::KeyArray
end

MooRedis::Database.create

describe Monkey do
  before do
    @monkey = Monkey.new
  end

  after do
    @monkey = nil
  end

  it "should find the object in the database and create initialize" do
    @monkey.update_data('25', 'franz')
    @monkey.save

    loaded_monkey = Monkey.find("25")
    assert_equal @monkey, loaded_monkey
    @monkey.destroy
  end

  it "should return nil when no object with that id is found" do
    assert_nil Monkey.find("30")
  end

  it "should initialize with empty array" do
    assert_equal([], @monkey)
  end

  it "should implement eql? and == and compare internal arrays" do
    cmp = ['franz']
    @monkey.update_data('25', cmp)
    assert @monkey == cmp
    assert @monkey.eql?(cmp)
  end

  it "should implement empty? like an array" do
    assert @monkey.empty?
    @monkey.update_data('25', 'franz')
    refute @monkey.empty?
  end

  it "should behave like an array on inspect and to_s" do
    cmp = ['franz']
    @monkey.update_data('25', cmp)
    assert_equal cmp.inspect, @monkey.inspect
    assert_equal cmp.to_s, @monkey.to_s
  end

  it "should set and get the values for each defined field" do
    [:name, :email, :created_at].each_with_index do |f, i|
      @monkey[i] = f.to_s
      assert_equal f.to_s, @monkey[i]
    end
  end

  it "should multiassign values with update_fields by automatism" do
    fields = ['name', 'email', 'created_at']
    @monkey.update_data('25', *fields)

    fields.each_with_index{ |f, i| assert_equal f, @monkey[i] }
  end

  describe "with set fields" do
    before do
      @monkey.update_data("klaus", "a@b.c", "kurz")
      if MooRedis::Database.db.exists("monkey:klaus")
        MooRedis::Database.db.del("monkey:klaus")
      end
    end

    after do
      @monkey.update_data('', [])
      if MooRedis::Database.db.exists("monkey:klaus")
        MooRedis::Database.db.del("monkey:klaus")
      end
    end

    it "should save to database" do
      @monkey.save
      saved_data = MooRedis::Transformations.transform("monkey:klaus")
      assert_equal @monkey, saved_data
    end

    it "should reload from the database" do
      @monkey.save
      data = @monkey.to_a
      @monkey.update_data(nil, 'franz')
      refute_equal data, @monkey
      @monkey.load
      assert_equal data, @monkey
    end

    it "should destroy the record in the database" do
      @monkey.save
      @monkey.destroy
      assert_nil Monkey.find(@monkey.id)
    end
  end
end

