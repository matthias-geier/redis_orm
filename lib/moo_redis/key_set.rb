
module MooRedis
  class KeySet < KeyValue
    def update_data(*values)
      id = values.shift
      values = values.first if values.first.is_a?(Array)
      self.id = id unless id.nil?
      unless values.is_a?(Array)
        raise ArgumentError.new("update_data expects an Array")
      end

      @data = values
      self.autosave
    end

    def save
      return false if self.id.to_s.empty?
      key = self.database_key
      Database.db.del(key)
      results = @data.map{ |v| Database.db.sadd(key, v) }
      return results.all?
    end

    def load
      key = self.database_key
      data = self.class.transform(key)
      self.update_data(nil, data)
    end

    def to_ary
      return @data.dup
    end
    alias_method :to_a, :to_ary

    def eql?(other)
      return self == other
    end

    def ==(other)
      return @data.sort == other.to_a.sort
    end
  end
end
