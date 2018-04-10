## Register our custom page action
record_types = AppConfig.has_key?(:aeon_fulfillment_record_types) ? AppConfig[:aeon_fulfillment_record_types]
                                                                  : ['archival_object', 'accession']
AppConfig[:pui_page_custom_actions] << {
  'record_type' => record_types,
  'erb_partial' => 'aeon/aeon_request_action'
}


