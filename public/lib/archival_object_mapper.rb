class ArchivalObjectMapper < RecordMapper
    
    def initialize(archival_object)
        super(archival_object)
    end



    def json_fields
        mappings = super

        json = self.record.json
        if !json
            return mappings
        end 

        mappings['repository_processing_note'] = json['repository_processing_note']
        return mappings
    end


    # Returns a hash that maps from Aeon OpenURL values to values in the provided record.
    def map
        mappings = super

        mappings['component_id'] = self.record['component_id']

        return mappings
    end
end
