
module Redisabel
  class KeyHash < KeyValue
    include HashFunctions

    def self.data_type
      return Hash
    end

    def self.redis_store_method
      return :hset
    end

    def self.redis_delete_method
      return :hdel
    end

    def save
      return super do |key|
        key_values = @data.to_a.flatten
        next Database.db.hmset(key, *key_values) == Database::ok
      end
    end
  end
end
