gem 'minitest'

require 'redis'
require 'minitest/autorun'
require './moo_redis/extensions/string'
require './moo_redis/database'
require './moo_redis/transformations'
require './moo_redis/key_value'
require './moo_redis/key_array'
require './moo_redis/key_hash'

class User < MooRedis::KeyHash
end

MooRedis::Database.create

describe User do
  before do
    @user = User.new
  end

  after do
    @user = nil
  end

  it "should find the object in the database and create initialize" do
    @user.update_data(:name => 'franz', :id => '25')
    @user.save

    loaded_user = User.find("25")
    assert_equal @user, loaded_user
    @user.destroy
  end

  it "should return nil when no object with that id is found" do
    assert_nil User.find("30")
  end

  it "should initialize with empty hash" do
    assert_equal({}, @user)
  end

  it "should implement eql? and == and compare internal hashes" do
    cmp = { 'name' => 'foo' }
    @user.update_data(cmp)
    assert @user == cmp
    assert @user.eql?(cmp)
  end

  it "should implement empty? like a hash" do
    assert @user.empty?
    @user.update_data({ :name => 'foo' })
    refute @user.empty?
  end

  it "should behave like a hash on inspect and to_s" do
    cmp = { 'name' => 'foo' }
    @user.update_data(cmp)
    assert_equal cmp.inspect, @user.inspect
    assert_equal cmp.to_s, @user.to_s
  end

  it "should set and get the values for each defined field" do
    [:name, :email, :created_at].each_with_index do |f, i|
      @user[f] = "gnu#{i}"
      assert_equal "gnu#{i}", @user[f.to_s]
    end
  end

  it "should not set undefined fields" do
    @user[:moo] = "gnu"
    refute @user[:moo]
  end

  it "should multiassign values with update_fields by automatism" do
    fields = [:name, :email, :created_at]
    key_values = fields.reduce({}){ |acc, f| acc.merge({ f => "m#{f}" }) }
    @user.update_data(key_values)

    fields.each{ |f| assert_equal "m#{f}", @user[f.to_s] }
  end

  describe "with set fields" do
    before do
      @user.update_data(:id => "klaus", :email => "a@b.c", :created_at =>
        "2012-12-12", :name => "kurz")
      if MooRedis::Database.db.exists("user:klaus")
        MooRedis::Database.db.del("user:klaus")
      end
    end

    after do
      @user.update_data(:id => nil, :email => nil, :created_at => nil,
        :name => nil)
      if MooRedis::Database.db.exists("user:klaus")
        MooRedis::Database.db.del("user:klaus")
      end
    end

    it "should save to database" do
      @user.save
      saved_data = MooRedis::Transformations.transform("user:klaus")
      assert_equal @user, saved_data
    end

    it "should reload from the database" do
      @user.save
      data = @user.to_h
      @user.update_data({ :email => 'franz' })
      refute_equal data, @user
      @user.load
      assert_equal data, @user
    end

    it "should destroy the record in the database" do
      @user.save
      @user.destroy
      assert_nil User.find(@user.id)
    end
  end
end

