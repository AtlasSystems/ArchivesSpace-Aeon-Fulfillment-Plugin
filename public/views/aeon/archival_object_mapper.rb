class ArchivalObjectMapper 

    attr_reader :record

    def initialize(record) 
        @record = record 
    end 


    def repo_code
        self.record.resolved_repository.dig('repo_code').downcase 
    end


    def repo_settings
        AppConfig[:aeon_fulfillment][self.repo_code]
    end


    def show_action? 
        begin 
            if self.repo_settings 

                puts "-- Aeon Plugin checking for top containers." 
                has_top_container = false 

                if self.record['json'].present? && self.record['json']['instances'].present? 
                    self.record['json']['instances'].each do |instance| 
                        
                        sub_container = instance.dig('sub_container') 
                        next if !sub_container 

                        top_container_uri = sub_container.dig('top_container', 'ref'); 

                        if !top_container_uri.blank? 
                            has_top_container = true 
                        end 
                    end 
                end 

                only_top_containers = self.repo_settings[:requests_permitted_for_containers_only] || false 

                puts "-- Aeon Plugin Containers found? #{has_top_container}" 
                puts "-- Aeon Plugin only_top_containers? #{only_top_containers}" 

                return (has_top_container || !only_top_containers)        
            end 

        rescue Exception => e 
            puts "Failed to create Aeon Request action." 
            puts e.message 
            puts e.backtrace.inspect 

        end 

        return false 
    end 


    # Returns a hash that maps from Aeon OpenURL 
    # values to values in the provided record. 
    def map 
        mappings = {} 

        if !self.show_action? return mappings 

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

        mappings['restrictions_apply'] = self.record['restrictions_apply'] 
        mappings['component_id'] = self.record['component_id'] 
        mappings['identifier'] = self.record['identifier'] 
        mappings['publish'] = self.record['publish'] 
        mappings['level'] = self.record['level'] 
        mappings['title'] = self.record['title'] 
        mappings['uri'] = self.record['uri'] 
        
        if record['agents'] 
            mappings['creators'] = self.record['agents'].map { |k| "#{k}" }.join("; ") 
        end 

        resolved_resource = self.record['_resolved_resource'] 
        if resolved_resource 
            
            resource_obj = resolved_resource[self.record['resource']] 
            if resource_obj 
                mappings['collection_id'] = "#{resource_obj[0]['id_0']} #{resource_obj[0]['id_1']} #{resource_obj[0]['id_2']} #{resource_obj[0]['id_3']}".rstrip 
                mappings['collection_title'] = resource_obj[0]['title'] 
            end 
        end 

        json = self.record['json'] 
        if json 
            mappings['repository_processing_note'] = json['repository_processing_note'] 
            mappings['display_string'] = json['display_string'] 
            mappings['language'] = json['language'] 
            mappings['mapping'] = json['mapping'] 

            if json['notes']  
                json['notes'].each do |note| 
                    if note['type'] == 'physloc' and note['content'].length > 0 
                        mappings['physical_location_note'] = note['content'].map { |cont| "#{cont}" }.join("; ") 
                    end 
                end 
            end 

            if json['dates'] 
                json['dates'].each do |date| 
                    mappings["#{date['label']}_date"] = date['expression'] 
                end 
            end 

            instances = json.fetch('instances') 
            if instances 
                instance_count = 0 
                instances.each do |instance| 
                    if !instance['digital_object'] 
                        instance_count += 1 

                        mappings['Request'] = "#{instance_count}" 
                        
                        mappings["instance_is_representative_#{instance_count}"] = instance['is_representative'] 
                        mappings["instance_last_modified_by_#{instance_count}"] = instance['last_modified_by'] 
                        mappings["instance_instance_type_#{instance_count}"] = instance['instance_type'] 
                        mappings["instance_created_by_#{instance_count}"] = instance['created_by'] 

                        mappings['instance_container_grandchild_indicator'] = instance['indicator_3'] 
                        mappings['instance_container_child_indicator'] = instance['indicator_2'] 
                        mappings['instance_container_grandchild_type'] = instance['type_3'] 
                        mappings['instance_container_child_type'] = instance['type_2'] 

                        container = instance['sub_container'] 
                        if container 
                            mappings["instance_container_last_modified_by_#{instance_count}"] = container['last_modified_by'] 
                            mappings["instance_container_created_by_#{instance_count}"] = container['created_by'] 

                            top_container = container['top_container'] 
                            if top_container 
                                mappings["instance_top_container_uri_#{instance_count}"] = top_container['uri'] 

                                top_container_resolved = top_container['_resolved'] 
                                if top_container_resolved 
                                    mappings["instance_top_container_long_display_string_#{instance_count}"] = top_container_resolved['long_display_string'] 
                                    mappings["instance_top_container_last_modified_by_#{instance_count}"] = top_container_resolved['last_modified_by'] 
                                    mappings["instance_top_container_display_string_#{instance_count}"] = top_container_resolved['display_string'] 
                                    mappings["instance_top_container_restricted_#{instance_count}"] = top_container_resolved['restricted'] 
                                    mappings["instance_top_container_created_by_#{instance_count}"] = top_container_resolved['created_by'] 
                                    mappings["instance_top_container_indicator_#{instance_count}"] = top_container_resolved['indicator'] 
                                    mappings["instance_top_container_type_#{instance_count}"] = top_container_resolved['type'] 
                                end 
                            end 
                        end 
                    end 
                end 
            end 
        end 

        return mappings 
    end 
end 
