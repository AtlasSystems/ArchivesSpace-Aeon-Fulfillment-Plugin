class AeonResourceMapper < AeonRecordMapper

    include ManipulateNode

    register_for_record_type(Resource)

    def initialize(resource)
        super(resource)
    end
    
    # Override of #show_action? from AeonRecordMapper
    def show_action?
        return false if !super
        return self.requestable_based_on_archival_record_level?
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
        
        resource_identifier = [ json['id_0'], json['id_1'], json['id_2'], json['id_3'] ]
        mappings['collection_id'] = resource_identifier
            .reject {|id_comp| id_comp.blank?}
            .join('-')

        mappings['collection_title'] = strip_mixed_content(self.record['title'])

        mappings['ead_id'] = json['ead_id']
        mappings['ead_location'] = json['ead_location']
        mappings['finding_aid_title'] = json['finding_aid_title']
        mappings['finding_aid_subtitle'] = json['finding_aid_subtitle']
        mappings['finding_aid_filing_title'] = json['finding_aid_filing_title']
        mappings['finding_aid_date'] = json['finding_aid_date']
        mappings['finding_aid_author'] = json['finding_aid_author']
        mappings['finding_aid_description_rules'] = json['finding_aid_description_rules']
        mappings['resource_finding_aid_description_rules'] = json['resource_finding_aid_description_rules']
        mappings['finding_aid_language'] = json['finding_aid_language']
        mappings['finding_aid_sponsor'] = json['finding_aid_sponsor']
        mappings['finding_aid_edition_statement'] = json['finding_aid_edition_statement']
        mappings['finding_aid_series_statement'] = json['finding_aid_series_statement']
        mappings['finding_aid_status'] = json['finding_aid_status']
        mappings['finding_aid_note'] = json['finding_aid_note']

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

end
