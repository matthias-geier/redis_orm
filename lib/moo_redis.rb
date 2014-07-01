gem 'minitest'

require 'redis'
require 'minitest/autorun'

module MooRedis
  class Database
    attr_reader :db
    @@db = nil

    private_class_method :new
    def initialize(db=0)
      @db = Redis.new(:db => db)
    end

    def self.create(db=0)
      return if @@db
      @@db = new(db)
    end

    def self.close
      return unless @@db
      @@db.disconnect
    end

    def self.db
      return @@db.db if @@db
    end
  end

  module Transformations
    def self.detect_type(key)
      return Database.db.type(key)
    end

    def self.transform(key)
      type = self.detect_type(key)
      return self.send("transform_#{type}", key)
    end

    def self.transform_hash(key)
      db = Database.db
      keys = db.hkeys(key)
      values = db.hvals(key)
      return keys.zip(values).to_h
    end
  end

  class KeyValues
    include Transformations

    def self.fields(*columns)
      @@columns = columns
      columns.each do |c|
        define_method(c){ instance_variable_get("@#{c}") }
        define_method("#{c}="){ |v| instance_variable_set("@#{c}", v) }
      end
    end

    def update_fields(key_values)
      unless key_values.is_a?(Hash)
        raise ArgumentError.new("update_fields expects a Hash")
      end
      key_values.each do |k, v|
        self.send("#{k}=", v)
      end
    end

    def save
      id_name = @@columns.first
      raise RuntimeError.new('no columns defined') if id_name.nil?
      id_value = self.send(id_name)
      if id_value.nil? || id_value.empty?
        raise RuntimeError.new("column #{id_name} is unset")
      end
      key = "#{self.class.name}:#{id_value}"

      key_values = @@columns.reduce([]) do |acc, c|
        acc += [c, self.send(c)]
      end

      Database.db.hmset(key, *key_values)
    end

    def load
    end

    def self.find(id)
      id_name = @@columns.first
      raise RuntimeError.new('no columns defined') if id_name.nil?

      key = "#{self.class.name}:#{id_value}"
      return unless Database.db.exists(key)
      data = self.class.transform(key)
      return self.class.new.update_fields(data)
    end
  end
end


class User < MooRedis::KeyValues
  fields :name, :email, :created_at
end

MooRedis::Database.create

describe User do
  before do
    @user = User.new
  end

  after do
    @user = nil
  end

  it "should respond to defined field getters and setters" do
    [:name, :email, :created_at].each do |f|
      assert @user.respond_to?(f)
      assert @user.respond_to?("#{f}=")
    end
  end

  it "should set and get the values for each defined field" do
    [:name, :email, :created_at].each_with_index do |f, i|
      @user.send("#{f}=", "gnu#{i}")
      assert_equal "gnu#{i}", @user.send(f)
    end
  end

  it "should multiassign values with update_fields by automatism" do
    fields = [:name, :email, :created_at]
    key_values = fields.reduce({}){ |acc, f| acc.merge({ f => "m#{f}" }) }
    @user.update_fields(key_values)

    fields.each{ |f| assert_equal "m#{f}", @user.send(f) }
  end

  it "should multiassign values with update_fields by hand" do
    @user.update_fields(:name => 1, :email => 2)
    assert_equal 1, @user.name
    assert_equal 2, @user.email
  end

  describe "with set fields" do
    before do
      @user.update_fields(:name => "klaus", :email => "a@b.c", :created_at =>
        "2012-12-12")
      if MooRedis::Database.db.exists("User:klaus")
        MooRedis::Database.db.del("User:klaus")
      end
    end

    after do
      @user.update_fields(:name => nil, :email => nil, :created_at => nil)
      if MooRedis::Database.db.exists("User:klaus")
        MooRedis::Database.db.del("User:klaus")
      end
    end

    it "should save to database" do
      @user.save
      saved_data = MooRedis::Transformations.transform("User:klaus")

    end
  end
end

describe MooRedis::Database do
  it "should create a redis database connector" do
    assert_equal Redis, MooRedis::Database.db.class
  end
end
