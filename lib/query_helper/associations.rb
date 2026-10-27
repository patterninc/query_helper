require "query_helper/invalid_query_error"
require "query_helper/column_map"

class QueryHelper
  class Associations
    def self.process_association_params(associations)
      associations ||= []
      associations.class == String ? [associations.to_sym] : associations
    end

    def self.load_associations(payload:, associations: [], as_json_options: {})
      # dup so the generated include doesn't stick to the caller's options
      as_json_options = (as_json_options || {}).dup
      generated_include = as_json_options[:include].nil?
      as_json_options[:include] = json_associations(associations) if generated_include
      begin
        # Preloader have been changed in Rails 7, which is giving error on upgrade.
        # This should be updated to latest API once all repos have been upgraded to Rails 7
        ActiveRecord::Associations::Preloader.new.preload(payload, associations)
      rescue
        ActiveRecord::Associations::Preloader.new(records: payload, associations: associations).call
      end
      json = payload.as_json(as_json_options)
      # Included records serialize every column, so drop sensitive ones (Rails filter_attributes).
      # Callers that pass their own as_json include option control serialization themselves
      remove_sensitive_attributes(json, payload.first&.class, association_tree(associations)) if generated_include
      json
    end

    def self.remove_sensitive_attributes(json, model, tree, filters = {})
      Array.wrap(json).each do |record|
        next unless record.is_a?(Hash)
        tree.each do |name, nested|
          next unless record.key?(name.to_s)
          reflection = model.respond_to?(:reflect_on_association) ? model.reflect_on_association(name) : nil
          klass = reflection && !reflection.polymorphic? ? reflection.klass : ActiveRecord::Base
          filter = filters.fetch(klass) { filters[klass] = ColumnMap.sensitive_attribute_filter(klass) }
          if filter
            Array.wrap(record[name.to_s]).each do |child|
              child.reject! { |attribute, _| ColumnMap.sensitive_attribute?(klass, attribute, filter) } if child.is_a?(Hash)
            end
          end
          remove_sensitive_attributes(record[name.to_s], klass, nested, filters)
        end
      end
    end

    def self.preload_associations(payload:, preload: [])
      begin
        # Preloader have been changed in Rails 7, which is giving error on upgrade.
        # This should be updated to latest API once all repos have been upgraded to Rails 7
        ActiveRecord::Associations::Preloader.new.preload(payload, preload)
      rescue
        ActiveRecord::Associations::Preloader.new(records: payload, associations: preload).call
      end
    end

    # Raises unless every requested association (including nested ones) is in the allowed list.
    # Both lists use the same shape as the include param, e.g. [:parent, { children: [:toys] }]
    def self.validate_associations!(associations, allowed)
      check = lambda do |requested, permitted, path|
        requested.each do |name, nested|
          raise InvalidQueryError.new("Including '#{(path + [name]).join(".")}' is not allowed") unless permitted.key?(name)
          check.call(nested, permitted[name], path + [name])
        end
      end
      check.call(association_tree(associations), association_tree(allowed), [])
      associations
    end

    def self.association_tree(associations)
      associations = associations.to_unsafe_h if associations.respond_to?(:to_unsafe_h)
      associations = [associations] unless associations.is_a?(Array)
      associations.each_with_object({}) do |association, tree|
        association = association.to_unsafe_h if association.respond_to?(:to_unsafe_h)
        case association
        when nil
          next
        when Symbol, String
          tree[association.to_sym] ||= {}
        when Array
          tree.deep_merge!(association_tree(association))
        when Hash
          association.each { |key, value| (tree[key.to_sym] ||= {}).deep_merge!(association_tree(value)) }
        else
          raise InvalidQueryError.new("Invalid include '#{association}'")
        end
      end
    end

    def self.json_associations(associations)
      associations ||= []
      associations = associations.is_a?(Array) ? associations : [associations]
      associations.inject([]) do |translated, association|
        if association.is_a?(Symbol) || association.is_a?(String)
          translated << association.to_sym
        elsif association.is_a?(Array)
          translated << association.map(&:to_sym)
        elsif association.is_a?(Hash)
          translated_hash = {}
          association.each do |key, value|
            translated_hash[key.to_sym] = { include: json_associations(value) }
          end
          translated << translated_hash
        end
      end
    end
  end
end
