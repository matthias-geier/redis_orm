gem 'minitest'

require 'redis'
require 'minitest/autorun'
require './moo_redis/extensions/string'
require './moo_redis/database'
require './moo_redis/transformations'
require './moo_redis/hash_functions'
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
    @croc.id = 'croc'
    @croc.update_data(10 => 'gnu', 20 => 'blu')
    @croc.save

    loaded_croc = Croc.find("croc")
    assert_equal @croc, loaded_croc
    @croc.destroy
  end

  it "should return nil when no object with that id is found" do
    assert_nil Croc.find("30")
  end

  it "should initialize with empty hash" do
    assert_equal({}, @croc.value)
  end

  it "should set and get the values for each defined field" do
    [:name, :email, :created_at].each_with_index do |f, i|
      @croc[i] = f
      assert_equal f.to_s, @croc[i]
    end
  end

  it "should multiassign values with update_fields by automatism" do
    fields = [:name, :email, :created_at]
    i = -1
    key_values = fields.reduce({}){ |acc, f| acc.merge({ (i += 1) => f }) }
    @croc.update_data(key_values)

    fields.each_with_index{ |f, i| assert_equal f.to_s, @croc[i] }
  end

  describe "with set fields" do
    before do
      @croc.id = 'croc'
      @croc.update_data(40 => 'moo', 20 => 'gnu')
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
      assert_equal @croc.value, saved_data
    end

    it "should reload from the database" do
      @croc.save
      data = @croc.to_h
      @croc.delete(20)
      @croc.store(60, 'blu')
      refute_equal data, @croc.value
      @croc.load
      assert_equal data, @croc.value
    end

    it "should destroy the record in the database" do
      @croc.save
      @croc.destroy
      assert_nil Croc.find(@croc.id)
    end

    it "should delete records from the db when autoupdate is enabled" do
      @croc.autosave = true
      @croc.delete(20)
      assert_equal({ 40 => 'moo' }, Croc.find('croc').value)
    end

    it "should store records in the db when autoupdate is enabled" do
      @croc.autosave = true
      @croc.store(60, 'blu')
      assert_equal 'blu', Croc.find('croc')[60]
    end

    it "should find smaller ranges when requested" do
      @croc.store(60, 'blu')
      @croc.save
      assert_equal({ 40 => 'moo', 60 => 'blu' },
        Croc.range('croc', 35, 60).value)
    end
  end
end

