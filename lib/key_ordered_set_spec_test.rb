gem 'minitest'

require 'redis'
require 'minitest/autorun'
require './redisabel/extensions/string'
require './redisabel/database'
require './redisabel/transformations'
require './redisabel/hash_functions'
require './redisabel/key_value'
require './redisabel/key_ordered_set'

class Croc < Redisabel::KeyOrderedSet
end

Redisabel::Database.create

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

  describe "with set fields" do
    before do
      @croc.id = 'croc'
      @croc.update_data(40 => 'moo', 20 => 'gnu')
      if Redisabel::Database.db.exists("croc:croc")
        Redisabel::Database.db.del("croc:croc")
      end
    end

    after do
      @croc.id = nil
      @croc.value = {}
      if Redisabel::Database.db.exists("croc:croc")
        Redisabel::Database.db.del("croc:croc")
      end
    end

    it "should save to database" do
      @croc.save
      saved_data = Redisabel::Transformations.transform("croc:croc")
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

    it "should not be able to modify sliced objects" do
      @croc.save
      croc = Croc.range('croc', 35, 45)
      assert_raises(RuntimeError){ croc.value = {} }
      refute croc.save
      assert_raises(RuntimeError){ croc.load }
    end
  end
end

