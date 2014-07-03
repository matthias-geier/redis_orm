
module Redisabel
  class KeySet < KeyValue
    def self.data_type
      return Array
    end

    def update_data(*data)
      return super(data.flatten.uniq)
    end
    protected :update_data

    def save
      return super do |key|
        Database.db.del(key)
        results = @data.map{ |v| Database.db.sadd(key, v) }
        next results.all?
      end
    end

    def delete(value)
      if @data.delete(value) && self.autosave? && !self.id.to_s.empty?
        Database.db.srem(self.database_key, value)
      end
    end

    def push(*values)
      values = values.shift if values.first.is_a?(Array)
      values.uniq!
      @data += values - @data
      if self.autosave? && !self.id.to_s.empty?
        values.each{ |v| Database.db.sadd(self.database_key, v) }
      end
    end

    def to_ary
      return @data.dup
    end
    alias_method :to_a, :to_ary

    def ==(other)
      return (other.is_a?(KeyValue) && self.id == other.id &&
        @data.sort == other.value.sort)
    end

    def value=(val)
      super
      @data.uniq!
    end
  end
end
