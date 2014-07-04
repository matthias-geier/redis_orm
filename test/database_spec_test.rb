gem 'minitest'

require 'redis'
require 'redisabel'
require 'minitest/autorun'

Redisabel::Database.create

describe Redisabel::Database do
  it "should create a redis database connector" do
    assert_equal Redis, Redisabel::Database.db.class
  end
end
