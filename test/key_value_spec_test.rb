gem 'minitest'

require 'redis'
require 'redisabel'
require 'minitest/autorun'

class Mule < Redisabel::KeyValue
end

Redisabel::Database.create

describe Mule do
  before do
    @mule = Mule.new
  end

  after do
    @mule = nil
  end

  it "should find the object in the database and create initialize" do
    @mule.id = "25"
    @mule.value = '30'
    @mule.save

    loaded_mule = Mule.find("25")
    assert_equal @mule, loaded_mule
    @mule.destroy
  end

  it "should set the value correctly through value=" do
    @mule.value = '30'
    assert_equal "30", @mule.value
  end

  it "should return nil when no object with that id is found" do
    assert_nil Mule.find("30")
  end

  it "should initialize with empty string" do
    assert_equal "", @mule.value
  end

  it "should implement empty? on the internal string" do
    assert @mule.empty?
    @mule.value = 'foo'
    refute @mule.empty?
  end

  it "should implement eql? and == and compare internal strings" do
    value = 'foo'
    @mule.value = value
    assert @mule == Mule.new(false, nil, value)
    assert @mule.eql?(Mule.new(false, nil, value))
    assert_equal value, @mule.value
  end

  it "should implement inspect and to_s" do
    value = 'foo'
    @mule.value = value
    assert_equal "Mule: #{value.inspect}", @mule.inspect
    assert_equal "Mule:", @mule.to_s
  end

  it "should set autosave initially through constructor" do
    u = Mule.new(true, 'foo', 'bar')
    assert u.autosave?
    u = Mule.new(false, 'foo', 'bar')
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
      @mule.id = 'klaus'
      @mule.value = 'cool'
      if Redisabel::Database.db.exists("mule:klaus")
        Redisabel::Database.db.del("mule:klaus")
      end
    end

    after do
      @mule.id = ''
      @mule.value = ''
      if Redisabel::Database.db.exists("mule:klaus")
        Redisabel::Database.db.del("mule:klaus")
      end
    end

    it "should save to database" do
      @mule.save
      saved_data = Redisabel::Transformations.transform("mule:klaus")
      assert_equal @mule.value, saved_data
    end

    it "should reload from the database" do
      @mule.save
      data = @mule.value
      @mule.value = 'franz'
      refute_equal data, @mule.value
      @mule.load
      assert_equal data, @mule.value
    end

    it "should destroy the database entry" do
      @mule.save
      @mule.destroy
      assert_nil Mule.find(@mule.id)
    end

    it "should filter patterns into objects" do
      @mule.save
      @mule2 = Mule.new(true, 'fritz', @mule.value)
      @mule3 = Mule.new(true, 'franz', @mule.value)

      filtered_mules = Mule.filter('fr*')
      refute filtered_mules.include?(@mule)
      assert filtered_mules.include?(@mule2)
      assert filtered_mules.include?(@mule3)
      @mule2.destroy
      @mule3.destroy
    end
  end
end
