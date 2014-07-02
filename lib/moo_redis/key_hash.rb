
module MooRedis
  class KeyHash < KeyValue
    private :value, :value=

    def self.find(id, asave=false)
      key = "#{self.database_key_name}:#{id}"
      return unless Database.db.exists(key)
      return self.new(asave, transform(key))
    end

    def id
      return @data["id"]
    end

    def id=(value)
      @data["id"] = value
    end

    def [](key)
      return @data[key]
    end

    def []=(key, value)
      self.update_data({ key => value })
    end

    def update_data(key_values={})
      unless key_values.is_a?(Hash)
        raise ArgumentError.new("update_data expects a Hash")
      end

      key_values = key_values.reduce({}) do |acc, (k, v)|
        acc.merge({ k.to_s => v.to_s })
      end
      @data ||= {}
      @data.merge!(key_values)
      self.autosave
    end

    def save
      return false if self.id.to_s.empty?
      key = self.database_key
      key_values = @data.to_a.flatten
      return Database.db.hmset(key, *key_values) == Database::ok
    end

    def load
      key = self.database_key
      data = self.class.transform(key)
      self.update_data(data)
    end

    def to_hash
      return @data.dup
    end
    alias_method :to_h, :to_hash
  end
end
