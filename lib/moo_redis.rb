
describe MooRedis::Database do
  it "should create a redis database connector" do
    assert_equal Redis, MooRedis::Database.db.class
  end
end
