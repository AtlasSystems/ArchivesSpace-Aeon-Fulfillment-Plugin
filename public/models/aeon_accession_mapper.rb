class AeonAccessionMapper < AeonRecordMapper

    register_for_record_type(Accession)

    def initialize(accession)
        super(accession)
    end

    def json_fields
        mappings = super

        accession_identifier = [ json['id_0'], json['id_1'], json['id_2'], json['id_3'] ]
        mappings['accession_id'] = accession_identifier
            .reject {|id_comp| id_comp.blank?}
            .join('-')

        user_defined = json['user_defined']
        if user_defined
            mappings['user_defined_boolean_1'] = user_defined['boolean_1']
            mappings['user_defined_boolean_2'] = user_defined['boolean_2']
            mappings['user_defined_boolean_3'] = user_defined['boolean_3']
            mappings['user_defined_integer_1'] = user_defined['integer_1']
            mappings['user_defined_integer_2'] = user_defined['integer_2']
            mappings['user_defined_integer_3'] = user_defined['integer_3']
            mappings['user_defined_real_1'] = user_defined['real_1']
            mappings['user_defined_real_2'] = user_defined['real_2']
            mappings['user_defined_real_3'] = user_defined['real_3']
            mappings['user_defined_string_1'] = user_defined['string_1']
            mappings['user_defined_string_2'] = user_defined['string_2']
            mappings['user_defined_string_3'] = user_defined['string_3']
            mappings['user_defined_string_4'] = user_defined['string_4']
            mappings['user_defined_text_1'] = user_defined['text_1']
            mappings['user_defined_text_2'] = user_defined['text_2']
            mappings['user_defined_text_3'] = user_defined['text_3']
            mappings['user_defined_text_4'] = user_defined['text_4']
            mappings['user_defined_text_5'] = user_defined['text_5']
            mappings['user_defined_date_1'] = user_defined['date_1']
            mappings['user_defined_date_2'] = user_defined['date_2']
            mappings['user_defined_date_3'] = user_defined['date_3']
            mappings['user_defined_enum_1'] = user_defined['enum_1']
            mappings['user_defined_enum_2'] = user_defined['enum_2']
            mappings['user_defined_enum_3'] = user_defined['enum_3']
            mappings['user_defined_enum_4'] = user_defined['enum_4']
        end

        return mappings
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
