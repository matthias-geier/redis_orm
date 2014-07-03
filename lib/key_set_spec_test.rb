gem 'minitest'

require 'redis'
require 'minitest/autorun'
require './redisabel/extensions/string'
require './redisabel/database'
require './redisabel/transformations'
require './redisabel/key_value'
require './redisabel/key_set'

class Donkey < Redisabel::KeySet
end

Redisabel::Database.create

describe Donkey do
  before do
    @donkey = Donkey.new
  end

  after do
    @donkey = nil
  end

  it "should find the object in the database and create initialize" do
    @donkey.id = '25'
    @donkey.push('franz')
    @donkey.save

    loaded_donkey = Donkey.find("25")
    assert_equal @donkey, loaded_donkey
    @donkey.destroy
  end

  it "should return nil when no object with that id is found" do
    assert_nil Donkey.find("30")
  end

  it "should initialize with empty set" do
    assert_equal([], @donkey.value)
  end

  it "should implement eql? and == and compare internal sorted arrays" do
    cmp = ['franz']
    @donkey.push(cmp)
    assert @donkey == Donkey.new(false, nil, cmp)
    assert @donkey.eql?(Donkey.new(false, nil, cmp))
  end

  it "should implement empty? like an array" do
    assert @donkey.empty?
    @donkey.push('franz')
    refute @donkey.empty?
  end

  it "should behave like an array on inspect and to_s" do
    cmp = ['franz']
    @donkey.push(cmp)
    assert_equal "Donkey: #{cmp.inspect}", @donkey.inspect
    assert_equal "Donkey:", @donkey.to_s
  end

  it "should multiassign values with update_fields by automatism" do
    fields = ['name', 'email', 'created_at']
    @donkey.push(fields)

    fields.each{ |f| assert @donkey.value.include?(f) }
  end

  it "should not allow pushing of duplicates" do
    fields = ['name', 'name', 'email', 'created_at']
    @donkey.push(fields)
    assert_equal fields.uniq, @donkey.value
  end

  it "should push and delete from the set" do
    @donkey.push('moo')
    assert @donkey.value.include?('moo')
    @donkey.delete('moo')
    refute @donkey.value.include?('moo')
  end

  describe "with set fields" do
    before do
      @donkey.id = 'klaus'
      @donkey.push("klaus", "a@b.c", "kurz")
      if Redisabel::Database.db.exists("donkey:klaus")
        Redisabel::Database.db.del("donkey:klaus")
      end
    end

    after do
      @donkey.id = ''
      @donkey.value = []
      if Redisabel::Database.db.exists("donkey:klaus")
        Redisabel::Database.db.del("donkey:klaus")
      end
    end

    it "should save to database" do
      @donkey.save
      saved_data = Redisabel::Transformations.transform("donkey:klaus")
      assert_equal @donkey.value.sort, saved_data.sort
    end

    it "should reload from the database" do
      @donkey.save
      data = @donkey.to_a
      @donkey.push('franz')
      refute_equal data.sort, @donkey.value.sort
      @donkey.load
      assert_equal data.sort, @donkey.value.sort
    end

    it "should destroy the record in the database" do
      @donkey.save
      @donkey.destroy
      assert_nil Donkey.find(@donkey.id)
    end

    it "should push to the db with enabled autosave" do
      @donkey.autosave = true
      @donkey.push('moo')
      assert Donkey.find('klaus').value.include?('moo')
    end

    it "should delete from the db with enabled autosave" do
      @donkey.autosave = true
      @donkey.delete('klaus')
      refute Donkey.find('klaus').value.include?('moo')
    end
  end
end
