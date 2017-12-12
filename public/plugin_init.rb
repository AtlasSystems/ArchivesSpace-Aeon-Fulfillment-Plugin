## Register our custom page action

require_relative 'lib/record_mapper'
require_relative 'lib/archival_object_mapper'
require_relative 'lib/accession_mapper'

AppConfig[:pui_page_custom_actions] << {
  'record_type' => ['archival_object', 'accession'],
  'erb_partial' => 'aeon/aeon_request_action'
}


