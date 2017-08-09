## Register our custom page action
AppConfig[:pui_page_custom_actions] << {
  'record_type' => ['archival_object'], 
  'erb_partial' => 'aeon/aeon_request_action'
}