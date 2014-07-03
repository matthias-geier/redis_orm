
module MooRedis
  class KeyValue
    extend Transformations

    class << self; public :transform end
    attr_accessor :id

    def self.data_type
      return String
    end

    def self.find(id, asave=false)
      key = "#{self.database_key_name}:#{id}"
      return unless Database.db.exists(key)
      return self.new(asave, id, transform(key))
    end

    def self.database_key_name
      return self.name.underscore
    end

    def initialize(asave=false, id='', *data)
      @autosave = asave
      @data = self.class.data_type.new
      self.id = id || ''
      self.update_data(*data)
    end

    def update_data(*data)
      data = data.first || self.class.data_type.new
      unless data.is_a?(self.class.data_type)
        raise ArgumentError.new("update_data expects a #{self.class.data_type}")
      end
      @data = data
      self.autosave
    end

    def empty?
      return @data.empty?
    end

    def inspect
      return "#{self.class.name}:#{self.id} #{@data.inspect}"
    end

    def to_s
      return "#{self.class.name}:#{self.id}"
    end
    alias_method :to_str, :to_s

    def eql?(other)
      return self == other
    end

    def ==(other)
      return (other.is_a?(KeyValue) && self.id == other.id &&
        @data == other.value)
    end

    def save
      return false if self.id.to_s.empty?
      key = self.database_key
      return Database.db.set(key, @data) == Database::ok
    end

    def destroy
      key = self.database_key
      return Database.db.del(key) > 0
    end

    def load
      key = self.database_key
      data = self.class.transform(key)
      self.update_data(data)
    end

    def database_key
      return "#{self.class.database_key_name}:#{self.id}"
    end
    protected :database_key

    def autosave
      self.save if @autosave
    end
    protected :autosave

    def autosave?
      return @autosave
    end

    def autosave=(bool)
      @autosave = (bool == true)
      self.save if self.autosave?
    end

    def value
      return @data.dup
    end

    def value=(val)
      unless val.is_a?(self.class.data_type)
        val = self.class.data_type.new
      end
      @data = val
    end
  end
end
