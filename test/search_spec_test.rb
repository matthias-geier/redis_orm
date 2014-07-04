gem 'minitest'

require 'redis'
require 'redisabel'
require 'minitest/autorun'

class Shark < Redisabel::KeyValue
end

class Dolphin < Redisabel::KeyValue
end

Redisabel::Database.create

describe Redisabel::Search do
  before do
    @shark1 = Shark.new(true, 'harry', 'fish')
    @shark2 = Shark.new(true, 'stooge', 'three')
    @dolphin1 = Dolphin.new(true, 'yaoi', 'blue')
    @dolphin2 = Dolphin.new(true, 'hamatsu', 'yamatsu')
  end

  after do
    @shark1.destroy
    @shark2.destroy
    @dolphin1.destroy
    @dolphin2.destroy
    @shark1 = @shark2 = @dolphin1 = @dolphin2 = nil
  end

  it "should find all keys with default pattern" do
    s = Redisabel::Search.new
    keys = s.keys
    assert keys.include?(@shark1.send(:database_key))
    assert keys.include?(@shark2.send(:database_key))
    assert keys.include?(@dolphin1.send(:database_key))
    assert keys.include?(@dolphin2.send(:database_key))
  end

  it "should find a subset of keys by pattern" do
    s = Redisabel::Search.new('*ha*')
    keys = s.keys
    assert keys.include?(@shark1.send(:database_key))
    assert keys.include?(@shark2.send(:database_key))
    refute keys.include?(@dolphin1.send(:database_key))
    assert keys.include?(@dolphin2.send(:database_key))
  end

  it "should find all objects with default pattern" do
    s = Redisabel::Search.new
    objects = s.objects
    assert objects.include?(@shark1)
    assert objects.include?(@shark2)
    assert objects.include?(@dolphin1)
    assert objects.include?(@dolphin2)
  end

  it "should group all objects with default pattern" do
    s = Redisabel::Search.new
    objects = s.objects_by_type
    assert objects[@shark1.class].include?(@shark1)
    assert objects[@shark2.class].include?(@shark2)
    assert objects[@dolphin1.class].include?(@dolphin1)
    assert objects[@dolphin2.class].include?(@dolphin2)
  end
end
