class AeonResourceMapper < AeonRecordMapper

    include ManipulateNode

    register_for_record_type(Resource)

    def initialize(resource)
        super(resource)
    end

    # Override of #show_action? from AeonRecordMapper
    def show_action?
        return false if !super

        self.requestable_based_on_archival_record_level?
    end

    # Override for AeonRecordMapper json_fields method.
    def json_fields
        mappings = super

        json = self.record.json
        return mappings unless json

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

        mappings
    end

end
