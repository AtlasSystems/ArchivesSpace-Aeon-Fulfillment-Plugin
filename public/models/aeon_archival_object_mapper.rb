class AeonArchivalObjectMapper < AeonRecordMapper

    register_for_record_type(ArchivalObject)

    def initialize(archival_object)
        super(archival_object)
    end


    # Override for AeonRecordMapper json_fields method.
    def json_fields
        mappings = super

        json = self.record.json
        if !json
            return mappings
        end

        if json['repository_processing_note'] && json['repository_processing_note'].present?
            mappings['repository_processing_note'] = json['repository_processing_note']
        end

        mappings['restrictions_apply'] = restrictions_apply?

        mappings
    end

    # Returns a hash that maps from Aeon OpenURL values to values in the provided record.
    def record_fields
        mappings = super

        mappings['component_id'] = self.record['component_id']

        mappings
    end

    def restrictions_apply?

        if self.record.json['restrictions_apply'] 
            return true
        end

        self.record['ancestors'].each do |ancestor|
            
            ancestor_record = archivesspace.get_record(ancestor)
            if log_record?
                Rails.logger.info("Aeon Fulfillment Plugin") { "Logging ancestor #{ancestor}" }
                Rails.logger.info("Aeon Fulfillment Plugin") { ancestor_record.to_yaml }
            end



            if (ancestor_record.json['restrictions_apply'] == true or ancestor_record.json['restrictions'] == true)
                return true
            end
        end
        return false
    end
end
