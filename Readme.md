# ArchivesSpace Request Fulfillment via Aeon

**Version:** 20180319

**Last Updated:** March 19, 2018


## Table of Contents

1. [ArchivesSpace Request Fulfillment via Aeon](#archivesspace-request-fulfillment-via-aeon)
    1. [Table of Contents](#table-of-contents)
    2. [Overview](#overview)
    3. [Changelog](#changelog)
    4. [Configuring Plugin Settings](#configuring-plugin-settings)
        1. [All Aeon Fulfillment Plugin Configuration Options](#all-aeon-fulfillment-plugin-configuration-options)
        2. [Example Configuration](#example-configuration)
    5. [Imported Fields](#imported-fields)
        1. [Common Fields](#common-fields)
        2. [Archival Object Fields](#archival-object-fields)
        3. [Accession Fields](#accession-fields)
    6. [OpenURL Mappings](#openurl-mappings)


## Overview

This plugin adds a new request button to archival objects that allows
researchers to place Aeon requests for archival objects discovered via the
ArchivesSpace Public User Interface.

The functionality provided by this plugin is meant to replace the existing
Public UI request action functionality for archival objects. As such, it is
recommended that the built in functionality be disabled by setting
`AppConfig[:pui_page_actions_request] = false` or by removing
`:archival_object` from your `AppConfig[:pui_requests_permitted_for_types]`
setting. The latter will allow you to use Aeon to fulfill archival_object
requests, while still allowing other object types to be requested via the
default email functionality. By using the 'per repository' configuration
options for the built in PUI requesting functionality, it is also possible to
configure some repositories to continue using the built in PUI requesting
feature for archival objects while allowing other repositories to use Aeon.

This plugin has been tested on ArchivesSpace version 2.2.0. Future releases of
ArchivesSpace may cause changes in the functionality of this plugin.


## Changelog

- **20170809** 
    - Initial release of this ArchivesSpace plugin
    - Added support for sending requests for Archival Objects to Aeon
- **20171110**
    - Added readme to include configuration resources
    - Removed an unused control
- **20171204**
    - Changes to readme and configuration resources
    - Bug fixes
- **20180111**
    - Moved core functionality out of the `.erb`
    - Added support for sending requests for Accessions to Aeon
    - Bug fixes
- **20180222**
    - Removed explicit references to aeon.dll from the ruby partial
    - This change was made to support Aeon installations that don't specify an
      explicit `aeon.dll` in the `:aeon_web_url`
    - If updating to or past this version, you may need to add `aeon.dll` to
      your settings for `:aeon_web_url`
- **20180319**
    - Added the `:request_in_new_tab`, `:hide_request_button`, and
      `:hide_button_for_accessions` settings. All are optional and default to
      false.
    - Fixed a bug where only the first container would be included in the
      request.
    - Markup is now stripped from the `title` parameter.
    - Plugin has been refactored so builtin ArchivesSpace functionality can be
      used.
- **20180524**
    - Fixed a bug with the `:requests_permitted_for_containers_only` setting
    - Added an `:aeon_site_code` setting, allowing sites to specify the Aeon
      site code that should be put into the Site field of the Aeon Transaction
      record.
    - Added a locale to the en.yml that allows sites to configure the icon on
      the Aeon request button without editing the `.html.erb` file directly.
      Please check https://fontawesome.com/ for the list of available icons.


## Configuring Plugin Settings

In order to configure this plugin, you will need to modify the
`config/config.rb` file of your ArchivesSpace installation. To enable the
plugin, you will need to add the following to the configuration file.

```ruby
AppConfig[:plugins] << 'aeon_fulfillment'
AppConfig[:aeon_fulfillment] = {}
```

Next, you will need to add the appropriate settings appropriate values for 
each repository that will use the plugin. In the sample below, replace 
`{repo_code}` with the repository code for each repository. The repo_code is 
also known as the repository's short name. The repo_code must be written using 
lower-case. 

```ruby
AppConfig[:aeon_fulfillment]['{repo_code}'] = {}
AppConfig[:aeon_fulfillment]['{repo_code}'][:aeon_web_url] = "{Your aeon web url}"
AppConfig[:aeon_fulfillment]['{repo_code}'][:aeon_return_link_label] = "{The text for the return link from Aeon}"
```

For example, to configure the plugin for a repository that has the short name 
"ATLAS", add the following to `config.rb`. 

```ruby
AppConfig[:plugins] << 'aeon_fulfillment'
AppConfig[:aeon_fulfillment] = {}
AppConfig[:aeon_fulfillment]['atlas'] = {}
AppConfig[:aeon_fulfillment]['atlas'][:aeon_web_url] = "https://your.institution.edu/aeon/aeon.dll"
AppConfig[:aeon_fulfillment]['atlas'][:aeon_return_link_label] = "ArchivesSpace"
AppConfig[:aeon_fulfillment]['atlas'][:aeon_site_code] = "AEON"
```

This plugin configuration can also be formatted using the implicit form of a 
Ruby hash. 

```ruby
AppConfig[:plugins] << 'aeon_fulfillment'
AppConfig[:aeon_fulfillment] = {
    "atlas" => {
        :aeon_web_url => "https://your.institution.edu/aeon/aeon.dll",
        :aeon_external_system_id => "ArchivesSpace"
    },
    "test-repo" => {
        :aeon_web_url => "https://your.institution.edu/aeon/aeon.dll",
        :aeon_site_code => "TEST",
        :aeon_external_system_id => "ArchivesSpace Test Tepo"
    }
}
```

### All Aeon Fulfillment Plugin Configuration Options

- **:aeon\_web\_url**. (Required). This setting specifies the web url that 
  points to an Aeon installation. The plugin will send requests to this url, 
  after adding the external requests endpoint (`aeon.dll?action=11&type=200`) 
  to the end. 

- **:aeon\_return\_link\_label**. (Required). This setting specifies the text 
  that will display on the button that takes users back to ArchivesSpace. 

- **:requests\_permitted\_for\_containers\_only**. This settings specifies 
  whether requests are limited to resources with top containers only. The 
  default for this setting is `false`. 

- **:aeon\_external\_system\_id**. This setting specifies the System ID, which 
  is used by Aeon to determine which mapping rules to use from its 
  OpenURLMapping table. Each repository configuration can have their own 
  System ID or they can have a duplicate System ID. 

- **:request\_in\_new\_tab**. This setting allows the Aeon request to appear
  in a different tab, when set to `true`. Defaults to `false`.

- **:hide\_request\_button**. This setting allows the request button to be
  hidden for the repository, when set to `true`. The button is hidden
  completely rather than shown disabled. Defaults to `false`.

- **:hide\_button\_for\_accessions**. This setting allows the request
  button to be hidden for accessions, when set to `true`. Defaults to
  `false`.

- **:aeon\_site\_code**. This setting specifies the string that is sent with
  the request in a field labeled `aeon_site_code`. This setting will not
  automatically set the `Site` field on the Aeon Transaction record. The site
  field has to be manually configured through the `OpenURLMapping` table. If 
  this setting is not specified in the settings for the repository, no Aeon
  site code will be sent.

### Example Configuration

```ruby
AppConfig[:plugins] << "aeon_fulfillment"

AppConfig[:aeon_fulfillment] = {
    "special research collections" => {
        :aeon_web_url => "https://your.institution.edu/aeon/aeon.dll",
        :aeon_return_link_label => "Back to ArchivesSpace",
        :aeon_external_system_id => "ArchivesSpace",
        :aeon_site_code => "SPECCOLL",
        :requests_permitted_for_containers_only => true
    },
    "test special collections" => {
        :aeon_web_url => "https://your.institution.edu/aeon/aeon.dll",
        :aeon_return_link_label => "Back to ArchivesSpace",
        :aeon_external_system_id => "ArchivesSpace Test",
        :aeon_site_code => "TEST",
        :requests_permitted_for_containers_only => false
    }
}
```


## Imported Fields

This plugin builds a form that is sent to Aeon through the external requests
(`?action=11&type=200`) endpoint of the Aeon Web interface. Below are the
names of the fields as they will appear in the request.

### Common Fields

These fields are imported from both Archival Object records and Accession
records.

- `SystemID`
- `ReturnLinkURL`
- `ReturnLinkSystemName`
- `aeon_site_code`
- `identifier`
- `publish` (true/false value)
- `level`
- `title`
- `uri`
- `collection_id`
- `collection_title`
- `repo_code`
- `repo_name`
- `language`
- `restrictions_apply` (true/false value)
- `display_string`
- `creators` 
    - semi-colon (`;`) separated string list
- `accessrestrict`
    - semi-colon (`;`) separated string list
    - contains the content from `accessrestrict` subnotes
- `physical_location_note`
    - semi-colon (`;`) separated string list 
    - contains the content from `physloc` notes
- `{date_label}_date`
    - semi-colon (`;`) separated string list 
    - contains the content from the `expression`s of the record's related 
      dates 
    - The plugin will group all of the related dates of each record based on 
      the date's label. For each distinct date label of the dates that are 
      linked to the record, the request to Aeon will contain a distinct date 
      parameter. Some examples of what to expect for the name of this field 
      include `creation_date`, `event_date`, and `other_date`. The full list 
      of values that could appear in place of the `{date_label}` placeholder 
      is controlled by the `date_label` enumeration of your ArchivesSpace 
      installation. 

The following fields are common to both Accession records and Archival Object
records, but are based on the number of instances associated with the record.
The number of requests sent to Aeon is equal to the number of instances
associated with the record. If there are no instances, only one request will
be sent to Aeon. All of these fields are dependant on the number of instances,
and the values of each may differ from instance to instance.

- `instance_is_representative`
- `instance_last_modified_by`
- `instance_instance_type`
- `instance_created_by`
- `instance_container_grandchild_indicator`
- `instance_container_child_indicator`
- `instance_container_grandchild_type`
- `instance_container_child_type`
- `instance_container_last_modified_by`
- `instance_container_created_by`
- `instance_top_container_ref`
- `instance_top_container_uri`
- `instance_top_container_long_display_string`
- `instance_top_container_last_modified_by`
- `instance_top_container_display_string`
- `instance_top_container_restricted`
- `instance_top_container_created_by`
- `instance_top_container_indicator`
- `instance_top_container_barcode`
- `instance_top_container_type`
- `instance_top_container_collection_identifier` (semi-colon (`;`) separated string list)
- `instance_top_container_collection_display_string` (semi-colon (`;`) separated string list)
- `instance_top_container_series_identifer` (semi-colon (`;`) separated string list)
- `instance_top_container_series_display_string` (semi-colon (`;`) separated string list)

### Archival Object Fields

In addition to the fields specified above, the following additional fields are
specific to requests made for Archival Object records.

- `repository_processing_note`
- `component_id`

### Accession Fields

In addition to the fields specified above, the following additional fields are
specific to requests made for Accession records.

- `use_restrictions_note`
- `access_restrictions_note`
- `language`
    - This field is also present on most Archival Object requests, but it is 
      mapped from a different location for Accession requests. 


## OpenURL Mappings

Below is a list of recommended Open URL mappings that should be set in Aeon.

The `rfr_id` column should exactly match the configured 
`:aeon_external_system_id` for each repository. Multiple repositories can have 
the same or different System IDs. 

The `AeonFieldName` column should exactly match an Aeon field name. 

Each value in the `OpenURLFieldValues` should contain a `<#replacement-tag>` 
that has a name that matches one of the field names from the [Imported Fields](#imported-fields) 
section. 

For more information on configuring Aeon for this system, please visit the 
[Submitting Requests via OpenURL](https://prometheus.atlas-sys.com/display/aeon/Submitting+Requests+via+OpenURL)
page of our documentation at https://prometheus.atlas-sys.com.

```sql
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'Site', '<#aeon_site_code>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemAuthor', '<#creators>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemDate', '<#creation_date>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemTitle', '<#title>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'Location', '<#instance_top_container_long_display_string>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemNumber', '<#instance_top_container_barcode>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemISxN', '<#physical_location_note>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemCallNumber', '<#physical_location_note>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'CallNumber', '<#physical_location_note>|<#collection_id>', 'NULL');
```

## Custom Mappers

The plugin provides default mappers for Accession and ArchivalObject records. To
support other record types, specify the list of supported record type in
configuration like this:

```ruby
  AppConfig[:aeon_fulfillment_record_types] = ['archival_object', 'accession', 'other_record_type']
```

It is possible to override the default mappers by providing a custom mapper class.
Mapper classes register to handle record types by calling the class method
#register_for_record_type(type), like this:

```ruby
  register_for_record_type(Accession)
```

The custom mapping class should inherit from one of the provided mapper classes and then
implement whatever custom mappings are required by overriding the relevant methods. (See
the default mappers for examples, as they override behavior from the base AeonRecordMapper class)

The custom mapping class can be loaded from another plugin provided it is listed after this
plugin in the array of plugins in the configuration.
