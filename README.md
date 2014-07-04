redisabel
=========

A minimal object mapper for the key-value based Redis database written in
Ruby under the BSD license.

This is a work in progress Ruby gem.


Dependencies
=========

To run the code a Redis database is required and these gems:
* redis
* minitest


Supported Features
=========

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


Usage
=========

Available data type implementations:
* Redisabel::KeyValue
* Redisabel::KeyHash
* Redisabel::KeySet
* Redisabel::KeyList
* Redisabel::KeyOrderedSet

```ruby
  require 'redis'
  require 'redisabel'

  Redisabel::Database.create

  class Monkey < Redisabel::Keyvalue
  end

  # the first param tells the object to autosave initially or when values change
  Monkey.new(true, 'Anton', 'Chimp')

  anton = Monkey.find('Anton')

  anton.value = 'No Chimp'
  anton.save
```


Tests
=========

Each data type implementation is sufficiently tested and can currently be run
by cloning the repository, navigating into the base folder and calling

```bash
  ruby -Ilib test/test_runner.rb
```
