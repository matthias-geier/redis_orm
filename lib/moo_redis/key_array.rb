
module MooRedis
  class KeyArray < KeyValue

    def self.data_type
      return Array
    end

    def [](i)
      return @data[i]
    end

    def delete(value)
      if @data.delete(value) && self.autosave? && !self.id.to_s.empty?
        Database.db.lrem(self.database_key, 0, value)
      end
    end

    def delete_at(i)
      if @data.delete_at(i) && self.autosave? && !self.id.to_s.empty?
        tmp_value = Time.now.to_s
        self.insert(i, tmp_value)
        Database.db.lrem(self.database_key, 0, tmp_value)
      end
    end

    def insert(i, value)
      params = i.nil? ? [value] : [i, value]
      amethod = i.nil? ? :push : :insert
      @data.send(amethod, *params)
      if self.autosave? && !self.id.to_s.empty?
        method = i.nil? ? :rpush : :lset
        Database.db.send(method, self.database_key, *params)
      end
    end
    alias_method :[]=, :insert

    def push(*values)
      values = values.shift if values.first.is_a?(Array)
      values.each{ |v| self.insert(nil, v) }
    end

    def save
      return super do |key|
        Database.db.del(key)
        results = @data.map{ |v| Database.db.rpush(key, v.to_s) }
        next results.all?
      end
    end

    def to_ary
      return @data
    end

    def to_a
      return @data.dup
    end
  end
end
