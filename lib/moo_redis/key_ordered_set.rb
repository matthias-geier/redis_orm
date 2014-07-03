
module MooRedis
  class KeyOrderedSet < KeyValue
    include HashFunctions

    def self.data_type
      return Hash
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
      return false if self.id.to_s.empty?
      key = self.database_key
      Database.db.del(key)
      results = @data.map{ |k, v| Database.db.zadd(key, k, v) }
      return results.all?
    end

    def delete(key)
      if (value = @data.delete(key)) && self.autosave? && !self.id.to_s.empty?
        Database.db.zrem(self.database_key, value)
      end
    end

    def store(key, value)
      @data.delete(key)
      @data.store(key, value.to_s)
      if self.autosave? && !self.id.to_s.empty?
        Database.db.zadd(self.database_key, key, value.to_s)
      end
    end
    alias_method :[]=, :store
  end
end
