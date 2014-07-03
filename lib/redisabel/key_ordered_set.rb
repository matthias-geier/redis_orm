
module Redisabel
  class KeyOrderedSet < KeyValue
    include HashFunctions

    def self.data_type
      return Hash
    end

    def self.redis_store_method
      return :zadd
    end

    def self.redis_delete_method
      return :zrem
    end

    def self.range(id, first, last)
      key = "#{self.database_key_name}:#{id}"
      return unless Database.db.exists(key)
      data = transform_zset(key, :zrangebyscore, first, last)
      return self.new(false, id, data)
    end

    def value=(val)
      if !val.respond_to?(:keys) || val.keys.any?{ |k| !self.key_valid?(k) }
        raise ArgumentError.new('ordered sets only accept numbers as Hash keys')
      end
      super
    end

    def save
      return super do |key|
        Database.db.del(key)
        results = @data.map do |k, v|
          Database.db.zadd(key, k, v)
        end
        next results.all?
      end
    end
  end
end
