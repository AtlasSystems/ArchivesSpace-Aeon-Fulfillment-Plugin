class AeonAccessionMapper < AeonRecordMapper

    register_for_record_type(Accession)

    def initialize(accession)
        super(accession)
    end

    # Returns a hash that maps from Aeon OpenURL values to values in the provided record.
    def record_fields
        mappings = super

        if record.use_restrictions_note && record.use_restrictions_note.present?
            mappings['use_restrictions_note'] = record.use_restrictions_note
        end

        if record.access_restrictions_note && record.access_restrictions_note.present?
            mappings['access_restrictions_note'] = record.access_restrictions_note
        end

        mappings['language'] = self.record['language']

        return mappings
    end
end
