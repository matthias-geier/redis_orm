
module MooRedis
  module Transformations
    def detect_type(key)
      return Database.db.type(key)
    end
    module_function :detect_type

    def transform(key)
      type = detect_type(key)
      return self.send("transform_#{type}", key)
    end
    module_function :transform

    def transform_hash(key)
      db = Database.db
      keys = db.hkeys(key)
      values = db.hvals(key)
      return keys.zip(values).to_h
    end
    module_function :transform_hash

    def transform_list(key)
      return Database.db.lrange(key, 0, -1)
    end
    module_function :transform_list

    def transform_string(key)
      return Database.db.get(key)
    end
    module_function :transform_string

    def transform_set(key)
      return Database.db.smembers(key)
    end
    module_function :transform_set

    def transform_zset(key)
      return Database.db.zrange(key, 0, -1, :withscores => true).
        reduce({}) do |acc, (v, k)|

        acc[k.to_i] ||= []
        acc[k.to_i] << v
        acc
      end
    end
    module_function :transform_zset
  end
end
