
module MooRedis
  class KeyHash < KeyValue
    include HashFunctions

    def self.data_type
      return Hash
    end

    def save
      return false if self.id.to_s.empty?
      key = self.database_key
      key_values = @data.to_a.flatten
      return Database.db.hmset(key, *key_values) == Database::ok
    end

    def delete(key)
      if (value = @data.delete(key)) && self.autosave? && !self.id.to_s.empty?
        Database.db.hdel(self.database_key, value)
      end
    end

    def store(key, value)
      @data.delete(key)
      @data.store(key, value.to_s)
      if self.autosave? && !self.id.to_s.empty?
        Database.db.hset(self.database_key, key, value.to_s)
      end
    end
    alias_method :[]=, :store
  end
end
