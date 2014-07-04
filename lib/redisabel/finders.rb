
module Redisabel
  module Finders
    def find(id, asave=false)
      key = "#{self.database_key_name}:#{id}"
      return unless Database.db.exists(key)
      return self.new(asave, id, transform(key))
    end

    def filter(pattern, asave=false)
      filter_term = "#{self.database_key_name}:#{pattern}"
      keys = Database.db.keys(filter_term)
      return keys.map do |key|
        id = key.gsub("#{self.database_key_name}:", '')
        self.new(asave, id, transform(key))
      end
    end
  end
end
