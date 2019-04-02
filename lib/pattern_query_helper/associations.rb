module PatternQueryHelper
  class Associations
    def self.process_association_params(associations)
      associations ||= []
      if associations.class == String
        [associations.to_sym]
      else
        associations
      end
    end

    def self.load_associations(payload, associations)
      ActiveRecord::Associations::Preloader.new.preload(payload, associations)
      payload.as_json(include: json_associations(associations))
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
