class AeonAccessionMapper < AeonRecordMapper

    register_for_record_type(Accession)

    def initialize(accession)
        super(accession)
    end

    def json_fields
        mappings = super

        json = self.record.json
        return mappings unless json

        accession_identifier = [ json['id_0'], json['id_1'], json['id_2'], json['id_3'] ]
        mappings['accession_id'] = accession_identifier
            .reject {|id_comp| id_comp.blank?}
            .join('-')

        language = json['language']
        if language
            mappings['language'] = language
        end

        mappings
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

        mappings
    end
end
