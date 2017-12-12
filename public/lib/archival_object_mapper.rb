class ArchivalObjectMapper < RecordMapper
    
    def initialize(archival_object)
        super(archival_object)
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

                        top_container_uri = sub_container.dig('top_container', 'ref')

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

        super
    end


    def json_fields
        mappings = super

        json = self.record.json
        if !json
            return mappings
        end 

        mappings['repository_processing_note'] = json['repository_processing_note']
        return mappings
    end


    # Returns a hash that maps from Aeon OpenURL values to values in the provided record.
    def map
        mappings = super

        mappings['component_id'] = self.record['component_id']

        return mappings
    end
end
