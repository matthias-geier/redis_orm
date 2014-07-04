gem 'minitest'

require 'redis'
require 'redisabel'
require 'minitest/autorun'

class Logs < Redisabel::KeyOrderedSet
end

class LogEntry < Redisabel::KeyHash
end

Redisabel::Database.create

describe Logs do
  before do
    t = Time.now
    @logs = Logs.new(false, 'cookies')
    for i in 1...100000
      l = LogEntry.new(true, i-1, 'timestamp' => i, 'message' => "moo #{i}")
      @logs[i] = l
    end

    @logs.autosave = true
    puts "Initialized and saved 100000 entries in #{Time.now-t}s"
  end

  after do
    @logs.destroy
  end

  it "should store new entries sufficiently fast" do
    t = Time.now
    for i in 100000...200000
      @logs[i] = "LogEntry:#{i-1}"
    end
    puts "Stored 100000 entries one by one in #{Time.now-t}s"
  end

  it "should read all entries sufficiently fast" do
    t = Time.now
    Logs.find('cookies')
    puts "loaded 100000 entries into new object in #{Time.now-t}s"
  end

  it "should read a subset of entries sufficiently fast" do
    t = Time.now
    Logs.range('cookies', 15000, 20000)
    puts "loaded 5000 entries into new object in #{Time.now-t}s"
  end

  it "should read and map a subset of entries sufficiently fast" do
    t = Time.now
    logs = Logs.range('cookies', 15000, 20000)
    logs.value = logs.value.
      reduce({}){ |acc, (k ,v)| acc[k] = LogEntry.find(v); acc }
    puts "loaded and mapped 5000 entries into a new object in #{Time.now-t}s"
  end

  it "should read and map a subset of entries sufficiently fast" do
    t = Time.now
    logs = Logs.find('cookies')
    logs.value = logs.value.
      reduce({}){ |acc, (k ,v)| acc[k] = LogEntry.find(v); acc }
    puts "loaded and mapped 100000 entries into a new object in #{Time.now-t}s"
  end
end
