# redisabel

A minimal object mapper for the key-value based Redis database written in
Ruby under the BSD license.

This is a work in progress Ruby gem.


## Dependencies

To run the code a Redis database is required and these gems:

* redis
* minitest


## Supported Features

redisabel represents all 5 data types from Redis in Ruby with a more or
less intuitive interface.

* Strings are a class utilizing a simple id-string pair
* Hashes are built into a class behaving like a Ruby Hash with slighly
  reduced functionality
* Ordered Sets also behave similar to Ruby Hashes but require a float as
  Hash keys and support a slicing operation
* Lists are a reduced Ruby Array
* Sets are built internally with an Array but without any [] accessors

As redisabel is an object mapper, each of the data types as Ruby classes
can be inherited and worked with. Saving such an inherited object will result
in a database key of <object class name in underscore notation>:<object key>.
Such a class inheriting from the above mentioned 5 data type implementations
is a model.

Searching is possible by key with wildcard patterns in the syntax supported by
Redis. Each model will have a find and filter method available. The first
searches for the exact key inside the model scope and filter will allow for
wildcards.  Additionally a search interface provides generic searching in all
keys with the option to reduce the results to objects of the appropriate model.


## Usage

Available data type implementations:

* Redisabel::KeyValue
* Redisabel::KeyHash
* Redisabel::KeySet
* Redisabel::KeyList
* Redisabel::KeyOrderedSet

Additionally a search class and a database connector.

### Setup

Every basic setup requires the necessary gems and an initial database instance.
This is achieved by these lines, afterwards can follow any Ruby code.

```ruby
  require 'redis'
  require 'redisabel'

  Redisabel::Database.create
```

### Autosave

Before starting with models, you need to decide on whether something should
autosave or not. When it is enabled, it means any change you make to the
internal data structure by using the default accessors (these are described
later on with each data type) will save automatically to Redis.
Some accessors are more efficient than others, more on that in the respective
sections.

```ruby
  # enable autosave and trigger an immediate save
  object.autosave = true

  # disable autosave
  object.autosave = false
```

Autosave can be automatically set through the model constructor, as parameter
in finders and the search. These will be passed along and saved into the object.
The default for all autosave is false!

These are the current ways to set autosave when creating the object rather than
setting it afterwards. Setting autosave in filter or search will put all
returned objects into autosave mode.

```ruby
  autosave = true

  model.new(autosave, "id", "value")
  model.find("id", autosave)
  model.filter("pattern", autosave)
  Redisabel::Search.new("pattern", autosave)
```

### Data types

When sceptical about the parameters of a data type, have a look at the
implementation!

#### KeyValue

This is a basic key-value pair. You can set a unique key and assign it a value.
It is also the basic implementation from which all other data types inherit from
within the gem.

The steps to using it are: Create a model, instance a model, call save, find the
key-value pair through finders or search.

```ruby
  class Monkey < Redisabel::Keyvalue
  end

  m = Monkey.new(false, 'Anton', 'Chimp')
  m.save

  anton = Monkey.find('Anton')
  anton.value = 'No Chimp'
  anton.save

  # additional methods
  anton.empty?
  => false

  anton.inspect
  => Monkey:Anton "No Chimp"

  anton.to_s # or to_str
  => Monkey:Anton

  # this will compare id and value of the models
  anton == Monkey.new(false, "Anton", "No Chimp")
  => true

  anton.eql?(object) # alias of ==

  anton.value = "moo"
  anton.load # loads the stored data again, overwriting the value
  anton.value
  => "No Chimp"

  anton.destroy
  => true

  anton.autosave?
  => false
```

#### KeyHash

This stores a Hash of key-value pairs, both of the elements are strings. All
methods from KeyValue are inherited and these are added:

```ruby
  class Donkey < Redisabel::KeyHash
  end

  d = Donkey.new(false, "John", "name" => "Doe", "age" => "20")
  d.save

  d.value
  => { "name" => "Doe", "age" => "20" }

  d["name"]
  => "Doe"

  d.delete("name")
  d.value
  => { "age" => "20" }

  d.store("name", "Doe") # or d["name"] = "Doe"
  d.value
  => { "age" => "20", "name" => "Doe"  }

  d.to_hash # a reference to value
  => { "age" => "20", "name" => "Doe"  }

  d.to_h # a dup to value
  => { "age" => "20", "name" => "Doe"  }

  d.to_a # or to_ary
  => ["20", "Doe"]

  # this calls store for any key-value pair given
  d.update_data("food" => "carrots", "location" => "peru")
```

#### KeyOrderedSet

This stores an ordered set of score-value pairs. The Ruby implementation of this
is a Hash mapping floats to strings. It inherits from KeyValue and KeyHash and adds these methods:

```ruby
  class Shark < Redisabel::KeyOrderedSet
  end

  s = Shark.new(true, "claus", 10 => "I", 20 => "can", 30 => "has")

  # a readonly subset of score-values
  claus = Shark.range("claus", 15, 35)
  claus.value
  => { 20 => "can", 30 => "has" }

  claus.frozen?
  => true
```

#### KeyArray

An internal Array is used to describe the list data type on Redis. It inherits
from KeyValue and adds these methods:

```ruby
  class Mule < Redisabel::KeyArray
  end

  m = Mule.new(false, "Arthur", "is", "a", "mule")
  m.save

  m.value
  => ["is", "a", "mule"]

  m[1]
  => "a"

  m.delete("mule")
  m.value
  => ["is", "a"]

  m.delete_at(0)
  m.value
  => ["a"]

  m.insert(0, "is")
  m.value
  => ["is", "a"]

  m.push("mule")
  m.value
  => ["is", "a", "mule"]

  m.to_ary # a reference to value
  => ["is", "a", "mule"]

  m.to_a # a dup to value
  => ["is", "a", "mule"]
```

#### KeySet

A Redis set is an unsorted list that may or may not change order between two
accesses. Internally the gem uses an array to store the set and sorts it
on comparison and similar calls. It inherits from KeyValue and adds these
methods:

```ruby
  class Ork < Redisabel::KeySet
  end

  o = Ork.new(true, "garrh", "swords", "axes", "spears")

  o.value
  => ["swords", "axes", "spears"]

  o.delete("axes")
  o.value
  => ["swords", "spears"]

  o.push("axes", "maces")
  o.value
  => ["swords", "spears", "axes", "maces"]

  o.to_a # or to_ary, both dup the value
  => ["swords", "spears", "axes", "maces"]
```

### Search

Searching by key can either by done model-specific with find and filter or
more generic with the search. The search is an instanced object for the sole
reason that it supports caching. It will query the database once and then
return the cached objects.

```ruby
  s = Redisabel::Search.new('*', true)
  s.keys
  s.objects
  s.objects_by_type
```

These 3 methods return the matching keys to the pattern, the model instances created from the values inside the keys and the model instances grouped by model.


## Tests

Each data type implementation is sufficiently tested and can currently be run
by cloning the repository, navigating into the base folder and calling

```bash
  ruby -Ilib test/test_runner.rb
```
