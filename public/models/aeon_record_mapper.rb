class AeonRecordMapper

    include ManipulateNode

    attr_reader :record

    def initialize(record)
        @record = record
    end

    def self.mapper_for(record)
      unless defined? @@mappers
        # initialize with the default mappers
        @@mappers = {
          'Accession' => 'AeonAccessionMapper', 
          'ArchivalObject' => 'AeonArchivalObjectMapper' 
        }
        if AppConfig.has_key?(:aeon_fulfillment_mappers)
          @@mappers.merge!(AppConfig[:aeon_fulfillment_mappers])
        end
      end

      if @@mappers.has_key?(record.class.to_s)
        Kernel.const_get(@@mappers[record.class.to_s]).new(record)
      else
        Rails.logger.info("Aeon Fulfillment Plugin -- This ArchivesSpace object type (#{record.class}) is not supported by this plugin.")
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

        false
    end

    # If #show_action? returns false, then the button is shown disabled
    def show_action?
        begin
            puts "Aeon Fulfillment Plugin -- Checking for plugin settings for the repository"

            if !self.repo_settings
                puts "Aeon Fulfillment Plugin -- Could not find plugin settings for the repository: \"#{self.repo_code}\"."
            else
                puts "Aeon Fulfillment Plugin -- Checking for top containers"
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

                only_top_containers = self.repo_settings[:requests_permitted_for_containers_only] || false

                puts "Aeon Fulfillment Plugin -- Containers found?    #{has_top_container}"
                puts "Aeon Fulfillment Plugin -- only_top_containers? #{only_top_containers}"

                return (has_top_container || !only_top_containers)
            end

        rescue Exception => e
            puts "Aeon Fulfillment Plugin -- Failed to create Aeon Request action."
            puts e.message
            puts e.backtrace.inspect

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

        if (!self.repo_settings[:aeon_site_code].blank?)
            mappings['aeon_site_code'] = self.repo_settings[:aeon_site_code]
        end

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

                request["instance_container_grandchild_indicator_#{instance_count}"] = instance['indicator_3']
                request["instance_container_child_indicator_#{instance_count}"] = instance['indicator_2']
                request["instance_container_grandchild_type_#{instance_count}"] = instance['type_3']
                request["instance_container_child_type_#{instance_count}"] = instance['type_2']

                container = instance['sub_container']
                if container
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


    protected :json_fields, :record_fields, :system_information
end
