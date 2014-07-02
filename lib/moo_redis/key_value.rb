
module MooRedis
  class KeyValue
    extend Transformations

    class << self; public :transform end
    attr_accessor :id

    def self.find(id, asave=false)
      key = "#{self.database_key_name}:#{id}"
      return unless Database.db.exists(key)
      return self.new(asave, id, transform(key))
    end

    def self.database_key_name
      return self.name.underscore
    end

    def initialize(asave=false, *data)
      @autosave = asave
      self.update_data(*data)
    end

    def update_data(*args)
      while(args.length < 2); args << ""; end
      id, val = args
      self.id = id unless id.nil?
      @data = val unless val.nil?
      self.autosave
    end

    def empty?
      return @data.empty?
    end

    def inspect
      return @data.inspect
    end

    def to_s
      return @data.to_s
    end
    alias_method :to_str, :to_s

    def eql?(other)
      return self == other
    end

    def ==(other)
      return @data == other
    end

    def save
      return false if self.id.to_s.empty?
      key = self.database_key
      return Database.db.set(key, @data) == Database::ok
    end

    def destroy
      key = self.database_key
      return Database.db.del(key) == 1
    end

    def load
      key = self.database_key
      data = self.class.transform(key)
      self.update_data(nil, data)
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
    end

    def value
      return @data
    end

    def value=(val)
      @data = val
    end
  end


end
