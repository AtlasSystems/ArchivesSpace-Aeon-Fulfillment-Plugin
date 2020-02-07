class AeonRecordMapper

    include ManipulateNode

    @@mappers = {}

    attr_reader :record, :container_instances

    def initialize(record)
        @record = record
        @container_instances = find_container_instances(record['json'] || {})
    end

    def archivesspace
        ArchivesSpaceClient.instance
    end

    def self.register_for_record_type(type)
        @@mappers[type] = self
    end

    def self.mapper_for(record)
        if @@mappers.has_key?(record.class)
            @@mappers[record.class].new(record)
        else
            Rails.logger.info("Aeon Fulfillment Plugin") { "This ArchivesSpace object type (#{record.class}) is not supported by this plugin." }
            raise
        end
    end

    def repo_code
        self.record.resolved_repository.dig('repo_code').downcase
    end

    def repo_settings
        AppConfig[:aeon_fulfillment][self.repo_code]
    end

    def user_defined_fields
        mappings = {}

        if (udf_setting = self.repo_settings[:user_defined_fields])
            if (user_defined_fields = (self.record['json'] || {})['user_defined'])

                # Determine if the list is a whitelist or a blacklist of fields.
                # If the setting is just an array, assume that the list is a
                # whitelist.
                if udf_setting == true
                    # If the setting is set to "true", then all fields should be
                    # pulled in. This is implemented as a blacklist that contains
                    # 0 values.
                    is_whitelist = false
                    fields = []

                    Rails.logger.debug("Aeon Fulfillment Plugin") { "Pulling in all user defined fields" }
                else
                    if udf_setting.is_a?(Array)
                        is_whitelist = true
                        fields = udf_setting
                    else
                        list_type = udf_setting[:list_type]
                        is_whitelist = (list_type == :whitelist) || (list_type == 'whitelist')
                        fields = udf_setting[:values] || udf_setting[:fields] || []
                    end

                    list_type_description = is_whitelist ? 'Whitelist' : 'Blacklist'
                    Rails.logger.debug("Aeon Fulfillment Plugin") { ":allow_user_defined_fields is a #{list_type_description}" }
                    Rails.logger.debug("Aeon Fulfillment Plugin") { "User Defined Field #{list_type_description}: #{fields}" }
                end

                user_defined_fields.each do |field_name, value|
                    if (is_whitelist ? fields.include?(field_name) : fields.exclude?(field_name))
                        mappings["user_defined_#{field_name}"] = value
                    end
                end
            end
        end

        mappings
    end

    # This method tests whether the button should be hidden. This determination is based
    # on the settings for the repository and defaults to false.
    def hide_button?
        # returning false to maintain the original behavior
        return false unless self.repo_settings

        return true if self.repo_settings[:hide_request_button]
        return true if self.repo_settings[:hide_button_for_accessions] && record.is_a?(Accession)

        if (types = self.repo_settings[:hide_button_for_access_restriction_types])
          notes = (record.json['notes'] || []).select {|n| n['type'] == 'accessrestrict' && n.has_key?('rights_restriction')}
                                              .map {|n| n['rights_restriction']['local_access_restriction_type']}
                                              .flatten.uniq

          # hide if the record notes have any of the restriction types listed in config
          return true if (notes - types).length < notes.length
        end

        false
    end

    # Determines if the :requestable_archival_record_levels setting is present
    # and exlcudes the 'level' property of the current record. This method is
    # not used by this class, because not all implementations of "abstract_archival_object"
    # have a "level" property that uses the "archival_record_level" enumeration.
    def requestable_based_on_archival_record_level?
        if (req_levels = self.repo_settings[:requestable_archival_record_levels])
            is_whitelist = false
            levels = []

            # Determine if the list is a whitelist or a blacklist of levels.
            # If the setting is just an array, assume that the list is a
            # whitelist.
            if req_levels.is_a?(Array)
                is_whitelist = true
                levels = req_levels
            else
                list_type = req_levels[:list_type]
                is_whitelist = (list_type == :whitelist) || (list_type == 'whitelist')
                levels = req_levels[:values] || req_levels[:levels] || []
            end

            list_type_description = is_whitelist ? 'Whitelist' : 'Blacklist'
            Rails.logger.debug("Aeon Fulfillment Plugin") { ":requestable_archival_record_levels is a #{list_type_description}" }
            Rails.logger.debug("Aeon Fulfillment Plugin") { "Record Level #{list_type_description}: #{levels}" }

            # Determine the level of the current record.
            level = ''
            if self.record.json
                level = self.record.json['level'] || ''
            end

            Rails.logger.debug("Aeon Fulfillment Plugin") { "Record's Level: \"#{level}\"" }

            # If whitelist, check to see if the list of levels contains the level.
            # Otherwise, check to make sure the level is not in the list.
            return is_whitelist ? levels.include?(level) : levels.exclude?(level)
        end

        true
    end

    # If #show_action? returns false, then the button is shown disabled
    def show_action?
        begin
            Rails.logger.debug("Aeon Fulfillment Plugin") { "Checking for plugin settings for the repository" }

            if !self.repo_settings
                Rails.logger.info("Aeon Fulfillment Plugin") { "Could not find plugin settings for the repository: \"#{self.repo_code}\"." }
            else
                Rails.logger.debug("Aeon Fulfillment Plugin") { "Checking for top containers" }

                has_top_container = record.is_a?(Container) || self.container_instances.any?

                only_top_containers = self.repo_settings[:requests_permitted_for_containers_only] || false

                # if we're showing the button for accessions, and this is an accession,
                # then don't require containers
                only_top_containers = self.repo_settings.fetch(:hide_button_for_accessions, false) if record.is_a?(Accession)

                Rails.logger.debug("Aeon Fulfillment Plugin") { "Containers found?    #{has_top_container}" }
                Rails.logger.debug("Aeon Fulfillment Plugin") { "only_top_containers? #{only_top_containers}" }

                return (has_top_container || !only_top_containers)
            end

        rescue Exception => e
            Rails.logger.error("Aeon Fulfillment Plugin") { "Failed to create Aeon Request action." }
            Rails.logger.error(e.message)
            Rails.logger.error(e.backtrace.inspect)

        end

        false
    end


    # Pulls data from the contained record
    def map
        mappings = {}

        mappings = mappings
            .merge(self.system_information)
            .merge(self.json_fields)
            .merge(self.record_fields)
            .merge(self.user_defined_fields)

        mappings
    end


    # Pulls data from AppConfig and ASpace System
    def system_information
        mappings = {}

        mappings['SystemID'] =
            if (!self.repo_settings[:aeon_external_system_id].blank?)
                self.repo_settings[:aeon_external_system_id]
            else
                "ArchivesSpace"
            end

        return_url =
            if (!AppConfig[:public_proxy_url].blank?)
                AppConfig[:public_proxy_url]
            elsif (!AppConfig[:public_url].blank?)
                AppConfig[:public_url]
            else
                ""
            end

        mappings['ReturnLinkURL'] = "#{return_url}#{self.record['uri']}"

        mappings['ReturnLinkSystemName'] =
            if (!self.repo_settings[:aeon_return_link_label].blank?)
                self.repo_settings[:aeon_return_link_label]
            else
                "ArchivesSpace"
            end

        mappings['Site'] = self.repo_settings[:aeon_site_code] if self.repo_settings.has_key?(:aeon_site_code)

        mappings
    end


    # Pulls data from self.record
    def record_fields
        mappings = {}

        Rails.logger.debug("Aeon Fulfillment Plugin") { "Mapping Record: #{self.record}" }

        mappings['identifier'] = self.record.identifier || self.record['identifier']
        mappings['publish'] = self.record['publish']
        mappings['level'] = self.record.level || self.record['level']
        mappings['title'] = strip_mixed_content(self.record['title'])
        mappings['uri'] = self.record.uri || self.record['uri']

        resolved_resource = self.record['_resolved_resource'] || self.record.resolved_resource
        if resolved_resource
            resource_obj = resolved_resource[self.record['resource']]
            if resource_obj
                collection_id_components = [
                    resource_obj[0]['id_0'],
                    resource_obj[0]['id_1'],
                    resource_obj[0]['id_2'],
                    resource_obj[0]['id_3']
                ]

                mappings['collection_id'] = collection_id_components
                    .reject {|id_comp| id_comp.blank?}
                    .join('-')

                mappings['collection_title'] = resource_obj[0]['title']
            end
        end

        resolved_repository = self.record.resolved_repository
        if resolved_repository
            mappings['repo_code'] = resolved_repository['repo_code']
            mappings['repo_name'] = resolved_repository['name']
        end

        if record['creators']
            mappings['creators'] = self.record['creators']
                .select { |cr| cr.present? }
                .map { |cr| cr.strip }
                .join("; ")
        end

        mappings
    end


    # Pulls relevant data from the record's JSON property
    def json_fields

        mappings = {}

        json = self.record.json
        return mappings unless json

        Rails.logger.debug("Aeon Fulfillment Plugin") { "Mapping Record JSON: #{json}" }

        mappings['language'] = json['language']

        notes = json['notes']
        if notes
            mappings['physical_location_note'] = notes
                .select { |note| note['type'] == 'physloc' and note['content'].present? }
                .map { |note| note['content'] }
                .flatten
                .join("; ")

            mappings['accessrestrict'] = notes
                .select { |note| note['type'] == 'accessrestrict' and note['subnotes'] }
                .map { |note| note['subnotes'] }
                .flatten
                .select { |subnote| subnote['content'].present? }
                .map { |subnote| subnote['content'] }
                .flatten
                .join("; ")
        end

        if json['dates']
            json['dates']
                .select { |date| date['expression'].present? }
                .group_by { |date| date['label'] }
                .each { |label, dates|
                    mappings["#{label}_date"] = dates
                        .map { |date| date['expression'] }
                        .join("; ")
                }
        end

        mappings['restrictions_apply'] = json['restrictions_apply']
        mappings['display_string'] = json['display_string']

        instances = self.container_instances
        return mappings unless instances

        mappings['requests'] = instances
            .each_with_index
            .map { |instance, i|
                request = {}

                instance_count = i + 1

                request['Request'] = "#{instance_count}"

                request["instance_is_representative_#{instance_count}"] = instance['is_representative']
                request["instance_last_modified_by_#{instance_count}"] = instance['last_modified_by']
                request["instance_instance_type_#{instance_count}"] = instance['instance_type']
                request["instance_created_by_#{instance_count}"] = instance['created_by']

                container = instance['sub_container']
                return request unless container

                request["instance_container_grandchild_indicator_#{instance_count}"] = container['indicator_3']
                request["instance_container_child_indicator_#{instance_count}"] = container['indicator_2']
                request["instance_container_grandchild_type_#{instance_count}"] = container['type_3']
                request["instance_container_child_type_#{instance_count}"] = container['type_2']
                request["instance_container_last_modified_by_#{instance_count}"] = container['last_modified_by']
                request["instance_container_created_by_#{instance_count}"] = container['created_by']

                top_container = container['top_container']
                return request unless top_container

                request["instance_top_container_ref_#{instance_count}"] = top_container['ref']

                top_container_resolved = top_container['_resolved']
                return request unless top_container_resolved

                request["instance_top_container_long_display_string_#{instance_count}"] = top_container_resolved['long_display_string']
                request["instance_top_container_last_modified_by_#{instance_count}"] = top_container_resolved['last_modified_by']
                request["instance_top_container_display_string_#{instance_count}"] = top_container_resolved['display_string']
                request["instance_top_container_restricted_#{instance_count}"] = top_container_resolved['restricted']
                request["instance_top_container_created_by_#{instance_count}"] = top_container_resolved['created_by']
                request["instance_top_container_indicator_#{instance_count}"] = top_container_resolved['indicator']
                request["instance_top_container_barcode_#{instance_count}"] = top_container_resolved['barcode']
                request["instance_top_container_type_#{instance_count}"] = top_container_resolved['type']
                request["instance_top_container_uri_#{instance_count}"] = top_container_resolved['uri']

                collection = top_container_resolved['collection']
                if collection
                    request["instance_top_container_collection_identifier_#{instance_count}"] = collection
                        .select { |c| c['identifier'].present? }
                        .map { |c| c['identifier'] }
                        .join("; ")

                    request["instance_top_container_collection_display_string_#{instance_count}"] = collection
                        .select { |c| c['display_string'].present? }
                        .map { |c| c['display_string'] }
                        .join("; ")
                end

                series = top_container_resolved['series']
                if series
                    request["instance_top_container_series_identifier_#{instance_count}"] = series
                        .select { |s| s['identifier'].present? }
                        .map { |s| s['identifier'] }
                        .join("; ")

                    request["instance_top_container_series_display_string_#{instance_count}"] = series
                        .select { |s| s['display_string'].present? }
                        .map { |s| s['display_string'] }
                        .join("; ")

                end

                container_locations = top_container_resolved["container_locations"]
                return request unless container_locations && container_locations.any?

                container_locations.each_with_index { |container_location, container_loc_number|
                    container_loc_number = container_loc_number + 1
                    
                    request["instance_container_location_#{container_loc_number}_status_#{instance_count}"] = container_location['status']
                    request["instance_container_location_#{container_loc_number}_start_date_#{instance_count}"] = container_location['start_date']
                    request["instance_container_location_#{container_loc_number}_end_date_#{instance_count}"] = container_location['end_date']
                    request["instance_container_location_#{container_loc_number}_note_#{instance_count}"] = container_location['note']
                    request["instance_container_location_#{container_loc_number}_ref_#{instance_count}"] = container_location['ref']

                    # TODO: This does not work, there is no resolved container location from
                    # what I can tell. This needs to be fetched with a call to the backend.
                    resolved_container_location = container_location["_resolved"]
                    if resolved_container_location
                        request["instance_container_location_#{container_loc_number}_uri_#{instance_count}"] = resolved_container_location['uri']
                        request["instance_container_location_#{container_loc_number}_title_#{instance_count}"] = resolved_container_location['title']
                        request["instance_container_location_#{container_loc_number}_building_#{instance_count}"] = resolved_container_location['building']
                        request["instance_container_location_#{container_loc_number}_floor_#{instance_count}"] = resolved_container_location['floor']
                        request["instance_container_location_#{container_loc_number}_room_#{instance_count}"] = resolved_container_location['room']
                        request["instance_container_location_#{container_loc_number}_area_#{instance_count}"] = resolved_container_location['area']
                        request["instance_container_location_#{container_loc_number}_barcode_#{instance_count}"] = resolved_container_location['barcode']
                        request["instance_container_location_#{container_loc_number}_classification_#{instance_count}"] = resolved_container_location['classification']
                        request["instance_container_location_#{container_loc_number}_coordinate_1_label_#{instance_count}"] = resolved_container_location['coordinate_1_label']
                        request["instance_container_location_#{container_loc_number}_coordinate_1_indicator_#{instance_count}"] = resolved_container_location['coordinate_1_indicator']
                        request["instance_container_location_#{container_loc_number}_coordinate_2_label_#{instance_count}"] = resolved_container_location['coordinate_2_label']
                        request["instance_container_location_#{container_loc_number}_coordinate_2_indicator_#{instance_count}"] = resolved_container_location['coordinate_2_indicator']
                        request["instance_container_location_#{container_loc_number}_coordinate_3_label_#{instance_count}"] = resolved_container_location['coordinate_3_label']
                        request["instance_container_location_#{container_loc_number}_coordinate_3_indicator_#{instance_count}"] = resolved_container_location['coordinate_3_indicator']
                        request["instance_container_location_#{container_loc_number}_temporary_#{instance_count}"] = resolved_container_location['temporary']
                    end
                }

                request
            }

        mappings
    end

    # Grabs a list of instances from the given jsonmodel, ignoring any digital object
    # instances. If the current jsonmodel does not have any top container instances, the
    # method will recurse up the record's resource tree, until it finds a record that does
    # have top container instances, and will pull the list of instances from there.
    def find_container_instances (record_json)

        current_uri = record_json['uri']

        Rails.logger.info("Aeon Fulfillment Plugin") { "Checking \"#{current_uri}\" for Top Container instances..." }
        Rails.logger.debug("Aeon Fulfillment Plugin") { "#{record_json.to_json}" }

        instances = record_json['instances']
            .reject { |instance| instance['digital_object'] }

        if instances.any?
            Rails.logger.info("Aeon Fulfillment Plugin") { "Top Container instances found" }
            return instances
        end

        parent_uri = ''

        if record_json['parent'].present?
            parent_uri = record_json['parent']['ref']
            parent_uri = record_json['parent'] unless parent_uri.present?
        elsif record_json['resource'].present?
            parent_uri = record_json['resource']['ref']
            parent_uri = record_json['resource'] unless parent_uri.present?
        end

        if parent_uri.present?
            Rails.logger.debug("Aeon Fulfillment Plugin") { "No Top Container instances found. Checking parent. (#{parent_uri})" }
            parent = archivesspace.get_record(parent_uri)
            parent_json = parent['json']
            return find_container_instances(parent_json)
        end

        Rails.logger.debug("Aeon Fulfillment Plugin") { "No Top Container instances found." }

        []
    end

    protected :json_fields, :record_fields, :system_information,
              :requestable_based_on_archival_record_level?,
              :find_container_instances, :user_defined_fields
end
