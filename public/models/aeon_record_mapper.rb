class AeonRecordMapper

    include ManipulateNode

    @@mappers = {}

    attr_reader :record, :container_instances

    def initialize(record)
        @record = record
        @container_instances = find_container_instances(record['json'] || {})
    end

    ExtendedRequestClient.init

    def archivesspace
        ExtendedRequestClient.instance
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

    def unrequestable_display_message
        if !self.requestable_based_on_archival_record_level?
            if (message = self.repo_settings[:disallowed_record_level_message])
                return message
            else
                return "Not requestable"
            end
        elsif !self.record_has_top_containers?
            if (message = self.repo_settings[:no_containers_message])
                return message
            else
                return "No requestable containers"
            end
        elsif self.record_has_restrictions?
            if (message = self.repo_settings[:restrictions_message])
                return message
            else
                return "Access restricted"
            end
        end
        return ""
    end
    
    # This method tests whether the button should be hidden. This determination is based
    # on the settings for the repository and defaults to false.
    def hide_button?
        # returning false to maintain the original behavior
        return false unless self.repo_settings

        if self.repo_settings[:hide_request_button]
            return true
        elsif (self.repo_settings[:hide_button_for_accessions] == true && record.is_a?(Accession))
            return true
        elsif self.requestable_based_on_archival_record_level? == false
            return true
        elsif self.record_has_top_containers? == false
            return true
        elsif self.record_has_restrictions? == true
            return true
        end
        return false
    end

    def record_has_top_containers?
        return record.is_a?(Container) || self.container_instances.any?
    end

    def record_has_restrictions?
        if (types = self.repo_settings[:hide_button_for_access_restriction_types])
            notes = (record.json['notes'] || []).select {|n| n['type'] == 'accessrestrict' && n.has_key?('rights_restriction')}
                                                .map {|n| n['rights_restriction']['local_access_restriction_type']}
                                                .flatten.uniq

            # hide if the record notes have any of the restriction types listed in config
            access_restrictions = true if (notes - types).length < notes.length

            # check each top container for restrictions
            # if all of them are unrequestable, we should hide the request button for this record
            has_requestable_container = false
            if (instances = self.container_instances)
                instances.each do |instance|
                    if (container = instance['sub_container'])
                        if (top_container = container['top_container'])
                            if (top_container_resolved = top_container['_resolved'])
                                tc_has_restrictions = (top_container_resolved['active_restrictions'] || [])
                                    .map{ |ar| ar['local_access_restriction_type'] }
                                    .flatten.uniq
                                    .select{ |ar| types.include?(ar)}
                                    .any?
                                if tc_has_restrictions == false
                                    has_requestable_container = true
                                end
                            end
                        end
                    end
                end
            end

            return access_restrictions || !has_requestable_container
        end

        return false
    end

    # Determines if the :requestable_archival_record_levels setting is present
    # and excludes the 'level' property of the current record. This method is
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

        resolved_top_container = self.record.resolved_top_container
        mappings['userestrict']  = ''
        if (resolved_top_container)
            resolved_top_container['active_restrictions'].each do |ar|
                if (ar['linked_records']['_resolved'])
                    userestrict = ar['linked_records']['_resolved']['notes']
                                        .select { |note| note['type'] == 'userestrict' and note['subnotes'] }
                                        .map { |note| note['subnotes'] }.flatten
                                        .select { |subnote| subnote['content'].present? }
                                        .map { |subnote| subnote['content'] }.flatten
                                        .join("; ")
                    mappings['userestrict'] = userestrict
                end
            end
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

        if json['rights_statements']
            mappings['rights_type'] = json['rights_statements'].map{ |r| r['rights_type']}.uniq.join(',')
        end

        digital_instances = json['instances'].select { |instance| instance['instance_type'] == 'digital_object'}
        if (digital_instances.any?)
            mappings["digital_objects"] = digital_instances.map{|d| d['digital_object']['ref']}.join(';')
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
   
                request["requestable_#{instance_count}"] = (top_container_resolved['active_restrictions'] || [])
                    .map{ |ar| ar['local_access_restriction_type'] }
                    .flatten.uniq
                    .select{ |ar| (self.repo_settings[:hide_button_for_access_restriction_types] || []).include?(ar)}
                    .empty?

                locations = top_container_resolved["container_locations"]
                if locations.any?
                    location_id = locations.sort_by { |l| l["start_date"]}.last()["ref"]
                    location = archivesspace.get_location(location_id)
                    request["instance_top_container_location_#{instance_count}"] = location["title"]
                    request["instance_top_container_location_id_#{instance_count}"] = location_id
                end

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

        # If we're in top container mode, we can skip this step, 
        # since we only want to present containers associated with the current record.
        if (!self.repo_settings[:top_container_mode])
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
        end

        Rails.logger.debug("Aeon Fulfillment Plugin") { "No Top Container instances found." }

        []
    end

    protected :json_fields, :record_fields, :system_information,
              :requestable_based_on_archival_record_level?,
              :find_container_instances, :user_defined_fields
end
