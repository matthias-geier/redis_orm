gem 'minitest'

require 'redis'
require 'minitest/autorun'
require './redisabel/extensions/string'
require './redisabel/database'
require './redisabel/transformations'
require './redisabel/hash_functions'
require './redisabel/key_value'
require './redisabel/key_hash'

class User < Redisabel::KeyHash
end

Redisabel::Database.create

describe User do
  before do
    @user = User.new
  end

  after do
    @user = nil
  end

  it "should find the object in the database and create initialize" do
    @user.id = '25'
    @user.update_data('name' => 'franz', 'id' => '25')
    @user.save

    loaded_user = User.find("25")
    assert_equal @user, loaded_user
    @user.destroy
  end

  it "should return nil when no object with that id is found" do
    assert_nil User.find("30")
  end

  it "should initialize with empty hash" do
    assert_equal({}, @user.value)
  end

  it "should implement eql? and == and compare internal hashes" do
    cmp = { 'name' => 'foo' }
    @user.update_data(cmp)
    assert @user == User.new(false, nil, cmp)
    assert @user.eql?(User.new(false, nil, cmp))
  end

  it "should implement empty? like a hash" do
    assert @user.empty?
    @user.update_data({ 'name' => 'foo' })
    refute @user.empty?
  end

  it "should behave like a hash on inspect and to_s" do
    cmp = { 'name' => 'foo' }
    @user.update_data(cmp)
    assert_equal User.new(false, nil, cmp).inspect, @user.inspect
    assert_equal User.new(false, nil, cmp).to_s, @user.to_s
  end

  it "should set and get the values for each defined field" do
    ['name', 'email', 'created_at'].each_with_index do |f, i|
      @user[f] = "gnu#{i}"
      assert_equal "gnu#{i}", @user[f.to_s]
    end
  end

  it "should multiassign values with update_fields by automatism" do
    fields = ['name', 'email', 'created_at']
    key_values = fields.reduce({}){ |acc, f| acc.merge({ f => "m#{f}" }) }
    @user.update_data(key_values)

    fields.each{ |f| assert_equal "m#{f}", @user[f.to_s] }
  end

  describe "with set fields" do
    before do
      @user.id = 'klaus'
      @user.update_data('id' => "klaus", 'email' => "a@b.c", 'created_at' =>
        "2012-12-12", 'name' => "kurz")
      if Redisabel::Database.db.exists("user:klaus")
        Redisabel::Database.db.del("user:klaus")
      end
    end

    after do
      @user.id = nil
      @user.value = {}
      if Redisabel::Database.db.exists("user:klaus")
        Redisabel::Database.db.del("user:klaus")
      end
    end

    it "should save to database" do
      @user.save
      saved_data = Redisabel::Transformations.transform("user:klaus")
      assert_equal @user.value, saved_data
    end

    it "should reload from the database" do
      @user.save
      data = @user.to_h
      @user.update_data({ 'email' => 'franz' })
      refute_equal data, @user.value
      @user.load
      assert_equal data, @user.value
    end

    it "should destroy the record in the database" do
      @user.save
      @user.destroy
      assert_nil User.find(@user.id)
    end
  end
end

