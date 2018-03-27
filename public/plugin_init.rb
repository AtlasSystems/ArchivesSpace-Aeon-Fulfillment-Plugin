## Register our custom page action
unless AppConfig.has_key?(:pui_page_custom_actions)
  AppConfig[:pui_page_custom_actions] << {
    'record_type' => ['archival_object', 'accession'],
    'erb_partial' => 'aeon/aeon_request_action'
  }
end


