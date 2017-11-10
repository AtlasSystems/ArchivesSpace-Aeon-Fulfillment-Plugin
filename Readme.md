ArchivesSpace Request Fulfillment via Aeon
==========================================
This plugin adds a new request button to archival objects that allows researchers to place Aeon requests for archival objects discovered via the ArchivesSpace Public User Interface.

The functionality provided by this plugin is meant to replace the existing Public UI request action functionality for archival objects. As such, it is recommended that the built in functionality be disabled by setting 'AppConfig[:pui_page_actions_request] = false' or by removing ':archival_object' from your 'AppConfig[:pui_requests_permitted_for_types]' setting.

**Add the following after your list of plugins has been initialized**
```ruby
AppConfig[:plugins] = << 'aeon_fulfillment'
AppConfig[:aeon_fulfillment] = {}
```

**Add the following settings and appropriate values for EACH repository that will use the plugin.  Replace '{repo_code}' with the appropriate repository code (also known as a short name) for the repository (lower-cased).**
```ruby
AppConfig[:aeon_fulfillment]['{repo_code}'] = {}
AppConfig[:aeon_fulfillment]['{repo_code}'][:aeon_web_url] = "{Your aeon web url}"
AppConfig[:aeon_fulfillment]['{repo_code}'][:aeon_return_link_label] = "{The text for the return link from Aeon}"
```

For example, to configure the addon for a repository with a code of "ATLAS" add the following to config.rb
```ruby
AppConfig[:plugins] = << 'aeon_fulfillment'
AppConfig[:aeon_fulfillment] = {}
AppConfig[:aeon_fulfillment]['atlas'] = {}
AppConfig[:aeon_fulfillment]['atlas'][:aeon_web_url] = "https://your.institution.edu/aeon/"
AppConfig[:aeon_fulfillment]['atlas'][:aeon_return_link_label] = "ArchivesSpace" 
```

**All Aeon Fulfillment Plugin Specific Configuration Options**
```ruby
# (required) The URL to your Aeon web site
AppConfig[:aeon_fulfillment]['{repo_code}'][:aeon_web_url]

# (required) The text to display on the button that takes users back to ArchivesSpace
AppConfig[:aeon_fulfillment]['{repo_code}'][:aeon_return_link_label]  

# Specifies whether requests are limited to resources with top containers only. Default is false.
AppConfig[:aeon_fulfillment]['{repo_code}'][:requests_permitted_for_containers_only]] 

# The system ID to match fields against in Aeon's OpenURLMapping table.
AppConfig[:aeon_fulfillment]['{repo_code}'][:aeon_external_system_id] 
```

**Fields imported from the resource (Incomplete list)**
- uri 
- identifier
- component_id
- title
- restrictions_apply
- level
- publish
- creator (as a semi-colon separated string list)

Recommended OpenURL Mappings
```sql
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemAuthor', '<#creators>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemDate', '<#created_date>|<#Created_date>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemTitle', '<#title>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemNumber', '<#barcode_1-container_>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'Location', '<#instance_top_container_long_display_string_1>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemAuthor', '<#creators>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemDate', '<#created_date>|<#Created_date>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemTitle', '<#title>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemNumber', '<#barcode_1-container>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'Location', '<#instance_top_container_long_display_string_1>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemISxN', '<#physical_location_note>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemCallNumber', '<#physical_location_note>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'CallNumber', '<#physical_location_note>|<#collection_id>', 'NULL');
```