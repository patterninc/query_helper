module PatternQueryHelper
  class Associations
    def self.process_association_params(associations)
      associations ||= []
      if associations.class == String
        return [associations.to_sym]
      else
        return associations.map { |x| x.to_sym }
      end
    end

    def self.load_associations(payload, associations)
      ActiveRecord::Associations::Preloader.new.preload(payload, associations)
      payload.as_json(include: associations)
    end
  end
end
