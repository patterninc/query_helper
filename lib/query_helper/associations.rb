require "query_helper/invalid_query_error"

class QueryHelper
  class Associations
    def self.process_association_params(associations)
      associations ||= []
      associations.class == String ? [associations.to_sym] : associations
    end

    def self.load_associations(payload:, associations: [], as_json_options: {})
      as_json_options ||= {}
      as_json_options[:include] = as_json_options[:include] || json_associations(associations)
      begin
        # Preloader have been changed in Rails 7, which is giving error on upgrade.
        # This should be updated to latest API once all repos have been upgraded to Rails 7
        ActiveRecord::Associations::Preloader.new.preload(payload, associations)
      rescue
        ActiveRecord::Associations::Preloader.new(records: payload, associations: associations).call
      end
      payload.as_json(as_json_options)
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
