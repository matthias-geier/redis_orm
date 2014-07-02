
module MooRedis
  class KeyOrderedSet < KeyValue

    def self.find(id, asave=false)
      key = "#{self.database_key_name}:#{id}"
      return unless Database.db.exists(key)
      return self.new(asave, id, transform(key))
    end

    def [](score)
      return @data[score]
    end

    def []=(score, value)
      self.update_data(nil, { score => value })
    end

    def value=(val)
      if !val.is_a?(Hash) || val.keys.any?{ |k| !k.is_a?(Numeric) }
        raise ArgumentError.new('ordered sets only accept numbers as Hash keys')
      end
      super
    end

    def update_data(*values)
      id = values.shift
      if values.first.is_a?(Hash)
        values = values.first
      else
        values = {}
      end
      self.id = id unless id.nil?
      if !values.is_a?(Hash) || values.keys.any?{ |k| !k.is_a?(Numeric) }
        raise ArgumentError.new("update_data expects numbers as Hash keys")
      end

      @data ||= {}
      @data = values.reduce(@data) do |acc, (k, v)|
        acc[k.to_i] ||= []
        v = [v] unless v.is_a?(Array)
        v.map!(&:to_s)
        acc[k.to_i] += v - (v & acc[k.to_i])
        acc
      end
      self.autosave
    end

    def save
      return false if self.id.to_s.empty?
      key = self.database_key
      Database.db.del(key)
      results = @data.map{ |k, v| Database.db.zadd(key, k, v) }
      return results.all?
    end

    def load
      key = self.database_key
      data = self.class.transform(key)
      @data = {}
      self.update_data(nil, data)
    end

    def to_hash
      return @data.dup
    end
    alias_method :to_h, :to_hash

    def to_ary
      return @data.values.flatten
    end
    alias_method :to_a, :to_ary

    def eql?(other)
      return self == other
    end

    def ==(other)
      return @data == other
    end
  end
end
