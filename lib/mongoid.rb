# encoding: utf-8
# Copyright (c) 2009, 2010 Durran Jordan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require "delegate"
require "singleton"
require "time"
require "ostruct"
require "active_support/core_ext"
require 'active_support/json'
require "active_support/inflector"
require "active_support/time_with_zone"
require "active_model"
require "active_model/callbacks"
require "active_model/conversion"
require "active_model/errors"
require "active_model/mass_assignment_security"
require "active_model/naming"
require "active_model/serialization"
require "active_model/translation"
require "active_model/validator"
require "active_model/validations"

# ********************************************************************************
# We're including the class attribute methods from activesupport 3.1.0
# to make our version of Mongoid work with newer rails versions
# ********************************************************************************
class Class # :nodoc:
  def class_inheritable_reader(*syms)
    options = syms.extract_options!
    syms.each do |sym|
      next if sym.is_a?(Hash)
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def self.#{sym}                                # def self.after_add
          read_inheritable_attribute(:#{sym})          #   read_inheritable_attribute(:after_add)
        end                                            # end
                                                       #
        #{"                                            #
        def #{sym}                                     # def after_add
          self.class.#{sym}                            #   self.class.after_add
        end                                            # end
        " unless options[:instance_reader] == false }  # # the reader above is generated unless options[:instance_reader] == false
      EOS
    end
  end

  def class_inheritable_writer(*syms)
    options = syms.extract_options!
    syms.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def self.#{sym}=(obj)                          # def self.color=(obj)
          write_inheritable_attribute(:#{sym}, obj)    #   write_inheritable_attribute(:color, obj)
        end                                            # end
                                                       #
        #{"                                            #
        def #{sym}=(obj)                               # def color=(obj)
          self.class.#{sym} = obj                      #   self.class.color = obj
        end                                            # end
        " unless options[:instance_writer] == false }  # # the writer above is generated unless options[:instance_writer] == false
      EOS
    end
  end

  def class_inheritable_array_writer(*syms)
    options = syms.extract_options!
    syms.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def self.#{sym}=(obj)                          # def self.levels=(obj)
          write_inheritable_array(:#{sym}, obj)        #   write_inheritable_array(:levels, obj)
        end                                            # end
                                                       #
        #{"                                            #
        def #{sym}=(obj)                               # def levels=(obj)
          self.class.#{sym} = obj                      #   self.class.levels = obj
        end                                            # end
        " unless options[:instance_writer] == false }  # # the writer above is generated unless options[:instance_writer] == false
      EOS
    end
  end

  def class_inheritable_hash_writer(*syms)
    options = syms.extract_options!
    syms.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def self.#{sym}=(obj)                          # def self.nicknames=(obj)
          write_inheritable_hash(:#{sym}, obj)         #   write_inheritable_hash(:nicknames, obj)
        end                                            # end
                                                       #
        #{"                                            #
        def #{sym}=(obj)                               # def nicknames=(obj)
          self.class.#{sym} = obj                      #   self.class.nicknames = obj
        end                                            # end
        " unless options[:instance_writer] == false }  # # the writer above is generated unless options[:instance_writer] == false
      EOS
    end
  end

  def class_inheritable_accessor(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_writer(*syms)
  end

  def class_inheritable_array(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_array_writer(*syms)
  end

  def class_inheritable_hash(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_hash_writer(*syms)
  end

  def inheritable_attributes
    @inheritable_attributes ||= EMPTY_INHERITABLE_ATTRIBUTES
  end

  def write_inheritable_attribute(key, value)
    if inheritable_attributes.equal?(EMPTY_INHERITABLE_ATTRIBUTES)
      @inheritable_attributes = {}
    end
    inheritable_attributes[key] = value
  end

  def write_inheritable_array(key, elements)
    write_inheritable_attribute(key, []) if read_inheritable_attribute(key).nil?
    write_inheritable_attribute(key, read_inheritable_attribute(key) + elements)
  end

  def write_inheritable_hash(key, hash)
    write_inheritable_attribute(key, {}) if read_inheritable_attribute(key).nil?
    write_inheritable_attribute(key, read_inheritable_attribute(key).merge(hash))
  end

  def read_inheritable_attribute(key)
    inheritable_attributes[key]
  end

  def reset_inheritable_attributes
    @inheritable_attributes = EMPTY_INHERITABLE_ATTRIBUTES
  end

  private
    # Prevent this constant from being created multiple times
    EMPTY_INHERITABLE_ATTRIBUTES = {}.freeze

    def inherited_with_inheritable_attributes(child)
      inherited_without_inheritable_attributes(child) if respond_to?(:inherited_without_inheritable_attributes)

      if inheritable_attributes.equal?(EMPTY_INHERITABLE_ATTRIBUTES)
        new_inheritable_attributes = EMPTY_INHERITABLE_ATTRIBUTES
      else
        new_inheritable_attributes = Hash[inheritable_attributes.map do |(key, value)|
          [key, value.duplicable? ? value.dup : value]
        end]
      end

      child.instance_variable_set('@inheritable_attributes', new_inheritable_attributes)
    end

    alias inherited_without_inheritable_attributes inherited
    alias inherited inherited_with_inheritable_attributes
end



require "will_paginate/collection"
require "mongo"
require "mongoid/errors"
require "mongoid/extensions"
require "mongoid/safe"
require "mongoid/associations"
require "mongoid/atomicity"
require "mongoid/attributes"
require "mongoid/callbacks"
require "mongoid/collection"
require "mongoid/collections"
require "mongoid/config"
require "mongoid/contexts"
require "mongoid/criteria"
require "mongoid/cursor"
require "mongoid/deprecation"
require "mongoid/dirty"
require "mongoid/extras"
require "mongoid/factory"
require "mongoid/field"
require "mongoid/fields"
require "mongoid/finders"
require "mongoid/hierarchy"
require "mongoid/identity"
require "mongoid/indexes"
require "mongoid/javascript"
require "mongoid/json"
require "mongoid/keys"
require "mongoid/logger"
require "mongoid/matchers"
require "mongoid/memoization"
require "mongoid/modifiers"
require "mongoid/multi_parameter_attributes"
require "mongoid/named_scope"
require "mongoid/paths"
require "mongoid/persistence"
require "mongoid/safety"
require "mongoid/scope"
require "mongoid/state"
require "mongoid/timestamps"
require "mongoid/validations"
require "mongoid/versioning"
require "mongoid/components"
require "mongoid/paranoia"
require "mongoid/document"

# add railtie
if defined?(Rails)
  require "mongoid/railtie"
end

# add english load path by default
I18n.load_path << File.join(File.dirname(__FILE__), "config", "locales", "en.yml")

module Mongoid #:nodoc

  MONGODB_VERSION = "1.6.0"

  class << self

    # Sets the Mongoid configuration options. Best used by passing a block.
    #
    # Example:
    #
    #   Mongoid.configure do |config|
    #     name = "mongoid_test"
    #     host = "localhost"
    #     config.allow_dynamic_fields = false
    #     config.master = Mongo::Connection.new.db(name)
    #     config.slaves = [
    #       Mongo::Connection.new(host, 27018, :slave_ok => true).db(name),
    #       Mongo::Connection.new(host, 27019, :slave_ok => true).db(name)
    #     ]
    #   end
    #
    # Returns:
    #
    # The Mongoid +Config+ singleton instance.
    def configure
      config = Mongoid::Config
      block_given? ? yield(config) : config
    end
    alias :config :configure

    # Easy convenience method for generating an alert from the
    # deprecation module.
    #
    # Example:
    #
    # <tt>Mongoid.deprecate("Method no longer used")</tt>
    def deprecate(message)
      Mongoid::Deprecation.instance.alert(message)
    end

    alias :config :configure
  end

  # Take all the public instance methods from the Config singleton and allow
  # them to be accessed through the Mongoid module directly.
  #
  # Example:
  #
  # <tt>Mongoid.database = Mongo::Connection.new.db("test")</tt>
  Mongoid::Config.public_instance_methods(false).each do |name|
    (class << self; self; end).class_eval <<-EOT
      def #{name}(*args)
        configure.send("#{name}", *args)
      end
    EOT
  end
end
