class AccessionMapper < RecordMapper

    def initialize(accession)
        super(accession)
    end

    # Returns a hash that maps from Aeon OpenURL values to values in the provided record.
    def map
        mappings = super

        if record.use_restrictions_note && !record.use_restrictions_note.blank?
            mappings['use_restrictions_note'] = record.use_restrictions_note
        end

        if record.access_restrictions_note && !record.access_restrictions_note.blank?
            mappings['access_restrictions_note'] = record.access_restrictions_note
        end

        return mappings
    end
end
