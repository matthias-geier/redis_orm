gem 'minitest'

require 'redis'
require 'minitest/autorun'
require './redisabel/extensions/string'
require './redisabel/database'
require './redisabel/transformations'
require './redisabel/key_value'
require './redisabel/key_array'

class Monkey < Redisabel::KeyArray
end

Redisabel::Database.create

describe Monkey do
  before do
    @monkey = Monkey.new
  end

  after do
    @monkey = nil
  end

  it "should find the object in the database and create initialize" do
    @monkey.id = '25'
    @monkey.push('franz')
    @monkey.save

    loaded_monkey = Monkey.find("25")
    assert_equal @monkey, loaded_monkey
    @monkey.destroy
  end

  it "should return nil when no object with that id is found" do
    assert_nil Monkey.find("30")
  end

  it "should initialize with empty array" do
    assert_equal([], @monkey.value)
  end

  it "should implement eql? and == and compare internal arrays" do
    cmp = ['franz']
    @monkey.value = cmp
    assert @monkey == Monkey.new(false, nil, cmp)
    assert @monkey.eql?(Monkey.new(false, nil, cmp))
  end

  it "should implement empty? like an array" do
    assert @monkey.empty?
    @monkey.push('franz')
    refute @monkey.empty?
  end

  it "should behave like an array on inspect and to_s" do
    cmp = ['franz']
    @monkey.value = cmp
    assert_equal "Monkey: #{cmp.inspect}", @monkey.inspect
    assert_equal "Monkey:", @monkey.to_s
  end

  it "should set and get the values for each defined field" do
    [:name, :email, :created_at].each_with_index do |f, i|
      @monkey[i] = f.to_s
      assert_equal f.to_s, @monkey[i]
    end
  end

  it "should multiassign values with update_fields by automatism" do
    fields = ['name', 'email', 'created_at']
    @monkey.push(*fields)

    fields.each_with_index{ |f, i| assert_equal f, @monkey[i] }
  end

  describe "with set fields" do
    before do
      @monkey.id = 'klaus'
      @monkey.push("klaus", "a@b.c", "kurz")
      if Redisabel::Database.db.exists("monkey:klaus")
        Redisabel::Database.db.del("monkey:klaus")
      end
    end

    after do
      @monkey.id = ''
      @monkey.value = []
      if Redisabel::Database.db.exists("monkey:klaus")
        Redisabel::Database.db.del("monkey:klaus")
      end
    end

    it "should save to database" do
      @monkey.save
      saved_data = Redisabel::Transformations.transform("monkey:klaus")
      assert_equal @monkey.value, saved_data
    end

    it "should reload from the database" do
      @monkey.save
      data = @monkey.to_a
      @monkey.push('franz')
      refute_equal data, @monkey.value
      @monkey.load
      assert_equal data, @monkey.value
    end

    it "should destroy the record in the database" do
      @monkey.save
      @monkey.destroy
      assert_nil Monkey.find(@monkey.id)
    end

    it "should delete records from the db when autoupdate is enabled" do
      @monkey.autosave = true
      @monkey.delete('klaus')
      assert_equal(["a@b.c", "kurz"], Monkey.find('klaus').value)
    end

    it "should store records in the db when autoupdate is enabled" do
      @monkey.autosave = true
      @monkey.push('blu')
      assert_equal(["klaus", "a@b.c", "kurz", 'blu'],
        Monkey.find('klaus').value)
    end
  end
end

