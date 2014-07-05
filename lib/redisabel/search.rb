
module Redisabel
  class Search
    def initialize(pattern='*', asave=false)
      @pattern = pattern
      @autosave = asave
    end

    def keys
      @keys ||= Database.db.keys(@pattern)
    end

    def objects
      self.keys
      @objects ||= @keys.map do |key|
        object_name, id = key.split(':')
        next object_name.camelize.constantize.new(@autosave, id,
          Transformations.transform(key))
      end
    end

    def objects_by_type
      self.objects
      @objects_by_type ||= @objects.reduce({}) do |acc, obj|
        acc[obj.class] ||= []
        acc[obj.class] << obj
        next acc
      end
    end
  end
end
