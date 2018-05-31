## Register our custom page action
record_types = AppConfig.has_key?(:aeon_fulfillment_record_types) ? AppConfig[:aeon_fulfillment_record_types]
                                                                  : ['archival_object', 'accession']

button_position = AppConfig.has_key?(:aeon_fulfillment_button_position) ? AppConfig[:aeon_fulfillment_button_position] : nil

Plugins::add_record_page_action_erb(record_types,
                                    'aeon/aeon_request_action',
                                    button_position)
