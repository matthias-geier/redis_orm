
module Redisabel
  module HashFunctions
    def key_valid?(key)
      return key.is_a?(Numeric)
    end
    protected :key_valid?

    def [](key)
      return @data[key]
    end

    def update_data(*data)
      data = data.first.is_a?(Hash) ? data.first : {}
      unless data.is_a?(self.class.data_type)
        raise ArgumentError.new("update_data expects a #{self.class.data_type}")
      end

      data.each{ |k, v| self.store(k, v) }
    end

    def delete(key)
      if (value = @data.delete(key)) && self.autosave? && !self.id.to_s.empty?
        Database.db.send(self.class.redis_delete_method, self.database_key,
          value)
      end
    end

    def store(key, value)
      @data.delete(key)
      @data.store(key, value.to_s)
      if self.autosave? && !self.id.to_s.empty?
        Database.db.send(self.class.redis_store_method, self.database_key, key,
          value.to_s)
      end
    end
    alias_method :[]=, :store

    def to_hash
      return @data
    end

    def to_h
      return @data.dup
    end

    def to_ary
      return @data.values.flatten
    end
    alias_method :to_a, :to_ary
  end
end
