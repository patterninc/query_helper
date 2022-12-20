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
