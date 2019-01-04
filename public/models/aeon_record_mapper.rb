class AeonRecordMapper

    include ManipulateNode

    @@mappers = {}

    attr_reader :record

    def initialize(record)
        @record = record
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

    # This method tests whether the button should be hidden. This determination is based
    # on the settings for the repository and defaults to false.
    def hide_button?
        # returning false to maintain the original behavior
        return false unless self.repo_settings

        return true if self.repo_settings.fetch(:hide_request_button, false)
        return true if self.repo_settings.fetch(:hide_button_for_accessions, false) && record.is_a?(Accession)

        if (types = self.repo_settings.fetch(:hide_button_for_access_restriction_types, false))
          notes = (record.json['notes'] || []).select {|n| n['type'] == 'accessrestrict' && n.has_key?('rights_restriction')}
                                              .map {|n| n['rights_restriction']['local_access_restriction_type']}
                                              .flatten.uniq

          # hide if the record notes have any of the restriction types listed in config
          return true if (notes - types).length < notes.length
        end

        false
    end

    # Determines if the :requestable_archival_record_levels setting is present
    # and exlcudes the 'level' property of the current record.
    def requestable_based_on_archival_record_level?

        req_levels = self.repo_settings[:requestable_archival_record_levels]
        if req_levels
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
                level = (self.record.json['level'] || '').downcase
            end

            Rails.logger.debug("Aeon Fulfillment Plugin") { "Record's Level: \"#{level}\"" }

            # If whitelist, check to see if the list of levels contains the level.
            # Otherwise, check to make sure the level is not in the list.
            return is_whitelist ? levels.include?(level) : !levels.include?(level)
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
                has_top_container = false

                instances = self.record.json['instances']
                if instances
                    instances.each do |instance|

                        sub_container = instance.dig('sub_container')
                        next if !sub_container

                        top_container_uri = sub_container.dig('top_container', 'ref')

                        if top_container_uri.present?
                            has_top_container = true
                        end
                    end
                end

                has_top_container = true if record.is_a?(Container)

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

        return mappings
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

        return mappings
    end


    # Pulls data from self.record
    def record_fields
        mappings = {}

        mappings['identifier'] = self.record.identifier || self.record['identifier']
        mappings['publish'] = self.record['publish']
        mappings['level'] = self.record.level || self.record['level']
        mappings['title'] = strip_mixed_content(self.record['title'])
        mappings['uri'] = self.record.uri || self.record['uri']

        resolved_resource = self.record['_resolved_resource'] || self.record.resolved_resource
        if resolved_resource
            resource_obj = resolved_resource[self.record['resource']]
            if resource_obj
                mappings['collection_id'] = "#{resource_obj[0]['id_0']} #{resource_obj[0]['id_1']} #{resource_obj[0]['id_2']} #{resource_obj[0]['id_3']}".rstrip
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

        if record.notes
            accessrestrict = record.notes['accessrestrict']
            if accessrestrict
                arSubnotes = accessrestrict['subnotes']
                if arSubnotes
                    mappings['accessrestrict'] = arSubnotes
                        .select { |arSubnote| arSubnote['content'].present? }
                        .map { |arSubnote| arSubnote['content'].strip }
                        .join("; ")
                end
            end
        end

        return mappings
    end


    # Pulls relevant data from the record's JSON property
    def json_fields

        mappings = {}

        json = self.record.json
        if !json
            return mappings
        end

        mappings['language'] = json['language']

        if json['notes']
            json['notes'].each do |note|
                if note['type'] == 'physloc' and !note['content'].blank?
                    mappings['physical_location_note'] = note['content'].map { |cont| "#{cont}" }.join("; ")
                end
            end
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

        instances = json.fetch('instances', false)
        if !instances
            return mappings
        end

        mappings['requests'] = instances
            .select{ |instance| !instance['digital_object'] }
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
                if container
                    request["instance_container_grandchild_indicator_#{instance_count}"] = container['indicator_3']
                    request["instance_container_child_indicator_#{instance_count}"] = container['indicator_2']
                    request["instance_container_grandchild_type_#{instance_count}"] = container['type_3']
                    request["instance_container_child_type_#{instance_count}"] = container['type_2']

                    request["instance_container_last_modified_by_#{instance_count}"] = container['last_modified_by']
                    request["instance_container_created_by_#{instance_count}"] = container['created_by']

                    top_container = container['top_container']
                    if top_container
                        request["instance_top_container_ref_#{instance_count}"] = top_container['ref']

                        top_container_resolved = top_container['_resolved']
                        if top_container_resolved
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

                        end
                    end
                end

                request
            }

        return mappings
    end


    protected :json_fields, :record_fields, :system_information, :requestable_based_on_archival_record_level?
end
