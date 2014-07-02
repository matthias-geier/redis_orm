gem 'minitest'

require 'redis'
require 'minitest/autorun'
require './moo_redis/extensions/string'
require './moo_redis/database'
require './moo_redis/transformations'
require './moo_redis/key_value'
require './moo_redis/key_ordered_set'

class Croc < MooRedis::KeyOrderedSet
end

MooRedis::Database.create

describe Croc do
  before do
    @croc = Croc.new
  end

  after do
    @croc = nil
  end

  it "should find the object in the database and create initialize" do
    @croc.update_data('croc', 10 => 'gnu', 20 => 'blu')
    @croc.save

    loaded_croc = Croc.find("croc")
    assert_equal @croc, loaded_croc
    @croc.destroy
  end

  it "should return nil when no object with that id is found" do
    assert_nil Croc.find("30")
  end

  it "should initialize with empty hash" do
    assert_equal({}, @croc)
  end

  it "should implement eql? and == and compare internal hashes" do
    cmp = { 10 => ['foo'], 20 => ['bar', 'mar'] }
    @croc.update_data('croc', cmp)
    assert @croc == cmp
    assert @croc.eql?(cmp)
  end

  it "should implement empty? like a hash" do
    assert @croc.empty?
    @croc.update_data('croc', 10 => 'foo', 20 => ['bar', 'gnar'])
    refute @croc.empty?
  end

  it "should behave like a hash on inspect and to_s" do
    cmp = { 10 => ['foo'], 20 => ['bar', 'gnar'] }
    @croc.update_data('croc', cmp)
    assert_equal cmp.inspect, @croc.inspect
    assert_equal cmp.to_s, @croc.to_s
  end

  it "should set and get the values for each defined field" do
    [:name, :email, :created_at].each_with_index do |f, i|
      @croc[i] = f
      assert_equal [f.to_s], @croc[i]
    end
  end

  it "should multiassign values with update_fields by automatism" do
    fields = [:name, :email, :created_at]
    i = -1
    key_values = fields.reduce({}){ |acc, f| acc.merge({ (i += 1) => f }) }
    @croc.update_data('croc', key_values)

    fields.each_with_index{ |f, i| assert_equal [f.to_s], @croc[i] }
  end

  describe "with set fields" do
    before do
      @croc.update_data('croc', 40 => 'moo', 20 => 'gnu')
      if MooRedis::Database.db.exists("croc:croc")
        MooRedis::Database.db.del("croc:croc")
      end
    end

    after do
      @croc.id = nil
      @croc.value = {}
      if MooRedis::Database.db.exists("croc:croc")
        MooRedis::Database.db.del("croc:croc")
      end
    end

    it "should save to database" do
      @croc.save
      saved_data = MooRedis::Transformations.transform("croc:croc")
      assert_equal @croc, saved_data
    end

    it "should reload from the database" do
      @croc.save
      data = @croc.to_h
      new_data = data.dup
      new_data.delete(20)
      @croc.update_data(nil, new_data.merge({ 60 => 'blu' }))
      refute_equal data, @croc
      @croc.load
      assert_equal data, @croc
    end

    it "should destroy the record in the database" do
      @croc.save
      @croc.destroy
      assert_nil Croc.find(@croc.id)
    end
  end
end

