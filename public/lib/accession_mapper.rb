class AccessionMapper < RecordMapper

    def initialize(accession)
        super(accession)
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


    # Returns a hash that maps from Aeon OpenURL values to values in the provided record.
    def map
        mappings = super

        if record.use_restrictions_note && !record.use_restrictions_note.blank?
            mappings['use_restrictions_note'] = record.use_restrictions_note
        end

        if record.access_restrictions_note && !record.access_restrictions_note.blank?
            mappings['access_restrictions_note'] = record.access_restrictions_note
        end

        return mappings
    end
end
