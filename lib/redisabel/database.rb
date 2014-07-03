
module Redisabel
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

    def self.ok
      return "OK"
    end
  end
end
