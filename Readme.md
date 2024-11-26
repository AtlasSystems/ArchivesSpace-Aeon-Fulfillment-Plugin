# ArchivesSpace Request Fulfillment via Aeon

**Version:** 20241126

**Last Updated:** November 26, 2024


## Table of Contents

1. [ArchivesSpace Request Fulfillment via Aeon](#archivesspace-request-fulfillment-via-aeon)
   1. [Table of Contents](#table-of-contents)
   2. [Overview](#overview)
   3. [Changelog](#changelog)
   4. [Requirements](#requirements)
   5. [Configuring Plugin Settings](#configuring-plugin-settings)
      1. [Per Repository Configuration Options](#per-repository-configuration-options)
         1. [`:aeon_web_url`](#aeonweburl)
         2. [`:aeon_return_link_label`](#aeonreturnlinklabel)
         3. [`:aeon_external_system_id`](#aeonexternalsystemid)
         4. [`:requests_permitted_for_containers_only`](#requestspermittedforcontainersonly)
         5. [`:request_in_new_tab`](#requestinnewtab)
         6. [`:hide_request_button`](#hiderequestbutton)
         7. [`:hide_button_for_accessions`](#hidebuttonforaccessions)
         8. [`:aeon_site_code`](#aeonsitecode)
         9. [`:hide_button_for_access_restriction_types`](#hidebuttonforaccessrestrictiontypes)
         10. [`:requestable_archival_record_levels`](#requestablearchivalrecordlevels)
         11. [`:top_container_mode`](#topcontainermode)
         12. [`:disallowed_record_level_message`](#disallowedrecordlevelmessage)
         13. [`:no_containers_message`](#nocontainersmessage)
         14. [`:restrictions_message`](#restrictionsmessage)
         15. [`:user_defined_fields`](#userdefinedfields)
      2. [Other Configuration Options](#other-configuration-options)
         1. [`:aeon_fulfillment_record_types`](#aeonfulfillmentrecordtypes)
         2. [`:aeon_fulfillment_button_position`](#aeonfulfillmentbuttonposition)
      3. [Example Configuration](#example-configuration)
   6. [Aeon Remote Authentication Configurations](#aeon-remote-authentication-configurations)
   7. [Imported Fields](#imported-fields)
      1. [Common Fields](#common-fields)
      2. [Archival Object Fields](#archival-object-fields)
      3. [Accession Fields](#accession-fields)
      4. [Resource Fields](#resource-fields)
      5. [User Defined Fields](#user-defined-fields)
   8. [OpenURL Mappings](#openurl-mappings)
   9. [Custom Mappers](#custom-mappers)
   10. [Configuring the Aeon Request Form Used](#configuring-the-aeon-request-form-used)


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

This plugin has been tested on ArchivesSpace version 3.3.1, and requires Aeon Server version 5.2.0 or greater. Future releases of
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
- **20180531**
    - Additions
        - Added support for custom record mappers.
        - Added support for specifying record types to be specified from the
          config.
        - Added support for hiding the button for records that have listed
          access restriction types.
        - Added support for positioning the Aeon request button relative to
          the other page actions.
    - Improvements
        - Renamed the mappers to include Aeon in the name for a bit of name
          safety.
        - Replaced the switch in the erb that finds the appropriate mapper for
          a record with a call to a class method `#mapper_for(record)` on the
          base record mapper class.
        - Changed the operation of the `aeon_site_code` mapping. No longer
          need to specify a mapping for the Aeon site code in the
          OpenURLMapping table. The Aeon DLL will automatically route the
          provided Site code directly into the Transaction record.
        - Now uses a method provided by ArchivesSpace to add the Aeon request
          button.
        - Now shows the button enabled for Accessions even if they don't have
          containers, in cases where requests are only permitted for
          containers as well as Accessions.
        - Improvements to checking to see if the current record is/has a
          container.
- **20180726**
    - Fixed a bug with imported instance data.
- **20190110**
    - Added support for requesting Resource records.
    - Added the `:requestable_archival_record_levels` setting
    - Added functionality to pull instance information from records that exist
      higher in the resource tree, if the current record does not have any top
      container instance information.
    - Added hover text to the "Aeon Request" button when it is disabled. This
      text is accessible through screen readers.
    - Changed log statements to use the default Rails logger
- **20190111**
    - The plugin now removes all HTML tags from form values
- **20190115**
    - Added the `:user_defined_fields` setting
- **20190529**
    - Bug fixes for compatibility with ArchivesSpace v2.6.0 RC1
- **20230302**
    - Added `:top_container_mode` setting to support new Aeon Archival Request form.
    - Added some additional mapping options.
- **20230725**
    - Added `:log_records` setting to reduce amount of data logged unless logging of full records is explicitly enabled.
- **20241126**
    - Fixed a bug that caused a login loop when `:top_container_mode` is false. 
    Rather than using action=11&type=200 in this case, the AeonForm is specified as 
    ExternalRequest with a hidden input instead.

## Requirements

- Aeon Server 5.2.0 or greater
- ArchivesSpace 3.3.1

## Configuring Plugin Settings

***Please note that the Aeon OpenURLMapping table must be configured in the Customization Manager 
before the plugin can be used and/or tested with ArchivesSpace. See the [OpenURL Mappings](#openurl-mappings) section 
for more information.*** 

***If you are using the Atlas Dual Auth Portal to handle remote authentication in Aeon, please ensure 
that it is configured to support POST data handling. See the [Aeon Remote Authentication Configurations](#aeon-remote-authentication-configurations) 
section for more information.***

In order to configure this plugin, you will need to modify the 
`config/config.rb` file of your ArchivesSpace installation. To enable the plugin,  
you will need to reference it in the plugin configuration option in this file. 
Please note that after enabling the plugin in the config.rb file, the ArchivesSpace 
service will need to be restarted to push the plugin to the ArchivesSpace interface.
In the following example, a reference to the `'aeon-fulfillment'` plugin has 
been added to the list of enabled plugins after the reference to the default `'local'` plugin:

```ruby
AppConfig[:plugins] = ['local', 'aeon_fulfillment']
```

Next, you will need to add the appropriate settings and values for 
each repository that will use the plugin. These settings should be placed directly under 
the line of code listing your enabled plugins shown above. In the sample below, replace 
`{repo_code}` with the repository code for each repository. The repo_code is 
also known as the repository's short name. **The repo_code must be written using 
lower-case.** Please also ensure that the `:aeon_return_link_label` setting 
is included directly below the `:aeon_web_url`.

```ruby
AppConfig[:aeon_fulfillment] = {}
AppConfig[:aeon_fulfillment]['{repo_code}'] = {}
AppConfig[:aeon_fulfillment]['{repo_code}'][:aeon_web_url] = "{Your aeon web url}"
AppConfig[:aeon_fulfillment]['{repo_code}'][:aeon_return_link_label] = "{The text for the return link from Aeon}"
```

For example, to configure the plugin for a repository that has the short name 
"ATLAS", add the following to `config.rb`. **Note: The `:aeon_site_code` setting should be 
removed if you are not assigning multiple repositories to separate Aeon site codes**

```ruby
AppConfig[:aeon_fulfillment] = {}
AppConfig[:aeon_fulfillment]['atlas'] = {}
AppConfig[:aeon_fulfillment]['atlas'][:aeon_web_url] = "https://your.institution.edu/aeon/aeon.dll"
AppConfig[:aeon_fulfillment]['atlas'][:aeon_return_link_label] = "ArchivesSpace"
AppConfig[:aeon_fulfillment]['atlas'][:aeon_site_code] = "AEON"
```

If preferred, this plugin configuration can also be formatted using the implicit form of a 
Ruby hash, with settings for each repository grouped within curly braces and 
separated one per line. A comma should follow each individual line until 
the end of the block of settings for the repository is reached, and also after 
the closing curly brace for each repository until the last repository is reached:

```ruby
AppConfig[:aeon_fulfillment] = {
    "atlas" => {
        :aeon_web_url => "https://your.institution.edu/aeon/aeon.dll",
        :aeon_return_link_label => "ArchivesSpace",
        :aeon_external_system_id => "ArchivesSpace"
    },
    "test-repo" => {
        :aeon_web_url => "https://your.institution.edu/aeon/aeon.dll",
        :aeon_return_link_label => "ArchivesSpace",
        :aeon_external_system_id => "ArchivesSpace Test Repo"
    }
}
```

### Per Repository Configuration Options

#### `:aeon_web_url`

**Required.** This setting specifies the web url that points to an Aeon
installation. The plugin will send requests to this url, after adding the
external requests endpoint (`?action=11&type=200`) to the end. If you are using
the Atlas Dual Auth Portal, this setting should point to that URL instead
(https://dualauthurl.institution.edu/login/").

#### `:aeon_return_link_label`

**Required.** This setting specifies the text that will display on the button
that takes users back to ArchivesSpace. Setting either `AppConfig[:public_proxy_url]`
or `AppConfig[:public_url]` in `config/config.rb` will influence the *link*
associated with this label. See the `ReturnLinkURL` field below.

#### `:aeon_external_system_id`

**Required.** This setting specifies the System ID, which is used by Aeon to
determine which mapping rules to use from its OpenURLMapping table. Each
repository configuration can have their own System ID or they can have a
duplicate System ID.

#### `:requests_permitted_for_containers_only`

This settings specifies whether requests are limited to resources with top
containers only. The default for this setting is `false`.

#### `:request_in_new_tab`

This setting allows the Aeon request to appear in a different tab, when set to
`true`. Defaults to `false`.

#### `:hide_request_button`

This setting allows the request button to be hidden for the repository, when set
to `true`. The button is hidden completely rather than shown disabled. Defaults
to `false`.

#### `:hide_button_for_accessions`

This setting allows the request button to be hidden for accessions, when set to
`true`. Defaults to `false`.

#### `:aeon_site_code`

This setting specifies the Aeon site code for a repository. If this setting is
not specified in the settings for the repository, no Aeon site code will be
sent.

#### `:hide_button_for_access_restriction_types`

This setting allows the request button to be hidden for any records that have
any of the listed values in the local_access_restriction_type field of the rights_restriction 
of the accessrestrict note. The value of this config item should be an array of restriction types, for example:

`:hide_button_for_access_restriction_types => ['RestrictedSpecColl']` 

By default, no restriction types are hidden.

#### `:log_records`

This setting will log the full content of ArchivesSpace records when set to true.
This can be useful for debugging mappings and plugin issues, but should not normally be enabled.

#### `:requestable_archival_record_levels`

This setting allows sites to restrict the types of Resources and Archival
Objects that are requestable, using the "level" property of the record. 

- The setting accepts a few different configurations, specifying either a
  "whitelist" or a "blacklist" of levels that should either have requesting
  enabled, or disabled.
- The values that are specified in this list must be entries in the Archival
  Record Level (`archival_record_level`) controlled value list. This list can be
  accessed in the Staff interface through
  http://archivesspace-staff.yourinstitution.edu/enumerations?id=32. The values
  specified in this setting must match the "Value" column of the enumeration.
  The "Translation" column of the enumeration CANNOT be used.

**Example 1:** Specifies a whitelist. Under this configuration, only Resources
and Archival Objects that have a level of either "item" or "file" will be
requestable.

```ruby
AppConfig[:aeon_fulfillment] = {
    "repo code" => {
        # ...
        :requestable_archival_record_levels => ["item", "file"]
    }
}
```

**Example 2:** Specifies a whitelist. Under this configuration, only Resources
and Archival Objects that have a level of either "item" or "file" will be
requestable. This configuration functions identically to the example
demonstrated in Example 1.

```ruby
AppConfig[:aeon_fulfillment] = {
    "repo code" => {
        # ...
        :requestable_archival_record_levels => {
            :list_type => :whitelist,
            :values => ["item", "file"]
        }
    }
}
```

**Example 3:** Specifies a blacklist. Under this configuration, Resources and
Archival Objects that have a level of either "Collection", "Series",
"Sub-Series", "Record Group", or "Sub-Group" cannot be requested through this
plugin.

```ruby
AppConfig[:aeon_fulfillment] = {
    "repo code" => {
        # ...
        :requestable_archival_record_levels => {
            :list_type => :blacklist,
            :values => ["collection", "series", "subseries", "recordgrp", "subgrp"]
        }
    }
}
```

#### `:top_container_mode`

This true/false setting controls whether or not the new top container mode is active for the given repository. This mode has two effects:

- Only top containers associated with the current record are requestable. If no top containers are associated with the current record, then the request button will be replaced by a message (see :no_containers_message setting below).

- When the user clicks the Aeon Request button, they will be taken to the new Aeon Box-Picker form to submit their request(s).

If this setting is true, then the :requests_permitted_for_containers_only should also be set to true.

#### `:disallowed_record_level_message`

This is the message that will be displayed instead of the Aeon Request button if the current record cannot be requested due to the values listed in the :requestable_archival_record_levels setting. If no value is provided, the default value will be "Not requestable". The message should be kept short (30 characters or less) for best appearance.


#### `:no_containers_message`

This is the message that will be displayed instead of the Aeon Request button if the current record has no associated topcontainers and :top_container_mode is active. If no value is provided, the default value will be "No requestable containers". The message should be kept short (30 characters or less) for best appearance.

#### `:restrictions_message`

This is the message that will be displayed instead of the Aeon Request button if the current record cannot be requested because it has active restrictions matching the values in the :hide_button_for_access_restriction_types setting. If no value is provided, the default value will be "Access Restricted". The message should be kept short (30 characters or less) for best appearance.


#### `:user_defined_fields`

This setting allows sites to specify which user defined fields are imported.
This setting applies to all records that use user defined fields. By default, no
user defined fields are pulled from the record into the HTML form. Any fields
that are imported will be labelled according to [the section on user defined fields below](#user-defined-fields).
The setting accepts a few different configurations:

- You can specify the setting as either `true` or `false`, indicating that all
  or none of the fields should be mapped into the HTML form. `false` is the
  default for this setting.
- You can specify the setting as either a "whitelist" or a "blacklist" of user
  defined fields that should or should not be mapped.
- The values that are specified in this list MUST be the names of the fields as
  they appear in the database and in the
  [user defined schema](https://github.com/archivesspace/archivesspace/blob/757f2d738d6aa74bcd219d0667d109b7bb9bb99b/common/schemas/user_defined.rb).
  The localizations/translations for these fields CANNOT be used.

**Example 1:** Specifies that all fields from the User Defined Fields should be
mapped into the HTML form. If `false` is used in place of true, none of the
fields will be imported. `false` is the default value.

```ruby
AppConfig[:aeon_fulfillment] = {
    "repo code" => {
        # ...
        :user_defined_fields => true
    }
}
```

**Example 2:** Specifies a whitelist, variation 1. Under this configuration,
only the 3 user defined fields that are listed will be imported into the HTML
form.

```ruby
AppConfig[:aeon_fulfillment] = {
    "repo code" => {
        # ...
        :user_defined_fields => ["text_1", "string_1", "real_2"]
    }
}
```

**Example 3:** Specifies a whitelist, variation 2. This configuration is
identical to **Example 2**.

```ruby
AppConfig[:aeon_fulfillment] = {
    "repo code" => {
        # ...
        :user_defined_fields => {
            :list_type => :whitelist,
            :values => ["text_1", "string_1", "real_2"]
        }
    }
}
```

**Example 4:** Specifies a blacklist. Under this configuration, all of the user
defined fields that are not specified in this list will be imported, except for
the ones that are listed.

```ruby
AppConfig[:aeon_fulfillment] = {
    "repo code" => {
        # ...
        :user_defined_fields => {
            :list_type => :blacklist,
            :values => [
                "text_1", "text_2", "text_3",
                "string_1", "string_2",
                "boolean_1", "boolean_2", "boolean_3"
            ]
        }
    }
}
```


### Other Configuration Options

The following configuration options apply globally, rather than for a particular
repository.

#### `:aeon_fulfillment_record_types`

This setting takes an array of record types. It allows this plugin to handle
additional record types via [custom mappers (see below)](#custom-mappers).

#### `:aeon_fulfillment_button_position`

This setting supports the positioning of the request button relative to the
other buttons appearing on a page. By default the button will appear to the
right of all built in buttons and to the left of any plugin buttons loaded
after it. Setting this to `0` will cause the request button to appear to the
left of the built in buttons.


### Example Configuration

```ruby
AppConfig[:plugins] = ['local', 'aeon_fulfillment']

AppConfig[:aeon_fulfillment_record_types] = ['accession', 'archival_object', 'resource']
AppConfig[:aeon_fulfillment_button_position] = 2

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


## Aeon Remote Authentication Configurations

This plugin is designed to send as much data from ArchivesSpace as possible to 
allow users to easily map fields on the Aeon side of the integration. As such, it uses POST 
data rather than GET parameters so that data does not get truncated. This can be problematic 
for some remote authentication systems. If you are using the Atlas Dual Auth Portal, it 
already has functionality to resolve this issue by persisting POST data during the remote 
authentication process so you can simply configure this plugin to send requests to it 
instead of directly to Aeon. However, please note that some additional configuration 
is required to enable POST data support for the Dual Auth Portal. If you use the Portal and 
are experiencing issues with POST data persistence between ArchivesSpace and Aeon, please 
see the [Using an Authentication Portal Landing Page](https://support.atlas-sys.com/hc/en-us/articles/360011821074#h_01FSYP1NVPGY3JGKTWPM9T3K7Q) 
page for information on configuring the Portal to support POST data. 

If you are not using the Atlas Dual Auth Portal with your 
remote authentication configuration or are having difficulty getting it configured 
correctly, please contact Atlas Support.


## Imported Fields

This plugin builds a form that is sent to Aeon through the external requests
(`?action=11&type=200`) endpoint of the Aeon Web interface. Below are the
names of the fields as they will appear in the request.

### Common Fields

These fields are imported from both Archival Object records and Accession
records.

- `SystemID`
- `ReturnLinkURL`
    - The return link is populated using either the `AppConfig[:public_proxy_url]`
      or the `AppConfig[:public_url]`, depending on which has a value. If both are
      set, then `AppConfig[:public_proxy_url]` takes precedence. If neither is
      specified in `config/config.rb`, then the ArchivesSpace default value
      (`http://localhost:8081` as of this writing) will be used. The URI of the
      requested record is suffixed to this value to form the complete return link.
- `ReturnLinkSystemName`
- `Site`
- `identifier`
- `publish` (true/false value)
- `level`
- `title`
- `uri`
- `repo_code`
- `repo_name`
- `language`
    - semi-colon (`;`) separated string list
    - contains the content from the `language` elements listed in `lang_materials`
    - for accessions, contains the single value in the `language` element
- `restrictions_apply` (true/false value)
- `display_string`
- `creators` 
    - semi-colon (`;`) separated string list
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
- `date_expression`
  - semi-colon (`;`) separated string list 
  -  contains the combined final_expressions of the single and inclusive dates associated with the record.
- `rights_type`
  - semi-colon (`;`) separated string list 
  - contains the combined rights_type values of all rights statements associated with the record.
- `digital_objects`
  - semi-colon (`;`) separated string list 
  - contains the IDs of all digital objects associated with the record.

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
- `instance_top_container_location_note`
- `instance_top_container_location_title`
- `instance_top_container_location_id`
- `instance_top_container_location_building`

### Archival Object Fields

In addition to the fields specified above, the following additional fields are
specific to requests made for Archival Object records.

- `accessrestrict`
    - semi-colon (`;`) separated string list
    - contains the content from `accessrestrict` subnotes
- `collection_id`
- `collection_title`
- `component_id`
- `physical_location_note`
    - semi-colon (`;`) separated string list 
    - contains the content from `physloc` notes
- `repository_processing_note`
- `userestrict`
  - semi-colon (`;`) separated string list 
  - contains the combined contents of all published userestrict notes associated with the record.

### Accession Fields

In addition to the fields specified in the list of common fields, the following
additional fields are specific to requests made for Accession records.

- `use_restrictions_note`
- `access_restrictions_note`
- `language`
    - This field is also present on most Archival Object requests, but it is 
      mapped from a different location for Accession requests. 
- `accession_id`

### Resource Fields

In addition to the fields specified in the list of common fields, the following
additional fields are specific to requests made for Resource records.

- `repository_processing_note`
- `collection_id`
- `collection_title`
- `ead_id`
- `ead_location`
- `finding_aid_title`
- `finding_aid_subtitle`
- `finding_aid_filing_title`
- `finding_aid_date`
- `finding_aid_author`
- `finding_aid_description_rules`
- `resource_finding_aid_description_rules`
- `finding_aid_language`
- `finding_aid_sponsor`
- `finding_aid_edition_statement`
- `finding_aid_series_statement`
- `finding_aid_status`
- `finding_aid_note`


### User Defined Fields

You can use the [`:user_defined_fields`](#userdefinedfields) setting
to configure which user defined fields are imported. These fields are imported
with the `"user_defined_"` prepended to the name of the field. Below shows the
formatting of all of the user defined fields, as they would exist in the HTML
form.

- `user_defined_boolean_1`
- `user_defined_boolean_2`
- `user_defined_boolean_3`
- `user_defined_integer_1`
- `user_defined_integer_2`
- `user_defined_integer_3`
- `user_defined_real_1`
- `user_defined_real_2`
- `user_defined_real_3`
- `user_defined_string_1`
- `user_defined_string_2`
- `user_defined_string_3`
- `user_defined_string_4`
- `user_defined_text_1`
- `user_defined_text_2`
- `user_defined_text_3`
- `user_defined_text_4`
- `user_defined_text_5`
- `user_defined_date_1`
- `user_defined_date_2`
- `user_defined_date_3`
- `user_defined_enum_1`
- `user_defined_enum_2`
- `user_defined_enum_3`
- `user_defined_enum_4`


## OpenURL Mappings

Below is a list of recommended Open URL mappings that should be set in Aeon.

1. The `rfr_id` column should exactly match the configured
   `:aeon_external_system_id` for each repository. Multiple repositories can
   have the same or different System IDs.

2. The `AeonFieldName` column should exactly match an Aeon field name.

3. Each value in the `OpenURLFieldValues` should contain a
   `<#replacement-tag>` that has a name that matches one of the field names
   from the [Imported Fields](#imported-fields) section.

The SQL script below can be used to add some basic mappings to the OpenURLMapping table in Aeon. 
Additional mappings can then be added manually to the table in the Aeon Customization Manager. 
For more information on configuring this feature Aeon, please visit the 
[Submitting Requests via OpenURL](https://support.atlas-sys.com/hc/en-us/articles/360011919573-Submitting-Requests-via-OpenURL)
page of our documentation.

```sql
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemAuthor', '<#creators>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemDate', '<#creation_date>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemTitle', '<#title>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'Location', '<#instance_top_container_long_display_string>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemNumber', '<#instance_top_container_barcode>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'ItemISxN', '<#physical_location_note>', 'NULL');
INSERT INTO OpenURLMapping (URL_Ver, rfr_id, AeonAction, AeonFieldName, OpenURLFieldValues, AeonValue) VALUES ('Default', 'ArchivesSpace', 'Replace', 'CallNumber', '<#physical_location_note>|<#collection_id>', 'NULL');
```


## Custom Mappers

The plugin provides default mappers for Accession and ArchivalObject records. To
support other record types, specify the list of supported record type in
configuration like this:

```ruby
  AppConfig[:aeon_fulfillment_record_types] = ['archival_object', 'accession', 'custom_record_type']
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


## Configuring the Aeon Request Form Used

It is possible to control the Aeon request form that fulfillment requests use by adding an entry to
the OpenURLMapping table for the `DocumentType` parameter. The new OpenURLMapping entry should
resemble `(Default, ArchivesSpace, Replace, DocumentType, [SomeDocumentType])`. For example, using
"Manuscript" in place of `[SomeDocumentType]` causes requests to use the `GenericRequestManuscript`
form. 

There is some complexity to controlling which form is used:

1. Aeon Transaction fields will populated if (a) there is an entry in OpenURLMapping for the Aeon Transaction
field and (b) if the result of evaluating tag strings from the `OpenURLFieldValues` column of the
OpenURLMapping table against the OpenUrl request from ArchivesSpace results in a non-empty value. Aeon
Transaction fields can also be populated directly, if there is a direct match between one of the parameters
of the OpenUrl request and a field in the Aeon Transaction table.

2. If DocumentType and RequestType are both not populated, or if their values do not make sense to
Aeon, then the Aeon Transaction will use the DefaultRequest form.

3. If DocumentType is not populated, or if it's populated as "Default", and RequestType is populated
as "Copy", then the Aeon Transaction will use the PhotoduplicationRequest form.

4. If DocumentType is not "Default", then the name of the form that the Aeon Transaction will use 
will be "GenericRequest", concatenated with the value stored in DocumentType parameter on the Aeon
Transaction.
