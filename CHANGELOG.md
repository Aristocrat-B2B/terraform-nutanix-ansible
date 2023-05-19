# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this
project adheres to [Semantic Versioning](http://semver.org/).

<a name="v2.0.0"></a>
## [v2.0.0] - 2023-05-19
Changed
- Improve `nutanix` user lock approach to cover cases when a virtual host is being re-created
- Delete all outputs as they were the same data as the one passed outside through variables but formatted differently. It should not be a responsibility of this module.
- Refactored locals usage. Deleted unnecessary
- Deleted vars:
  - `module_nic_list` - we'll rely on updated `host_entries`
  - `module_vms` - it was never used

- `host_entries`: now expects following structure:
```
  {
    host_name = {
      id = "unique host id"
      ip = "1.2.3.4"
    }
  }
```

<a name="v1.0.12"></a>
## [v1.0.12] - 2023-02-13
Changed
- Make `nutanix` user lock optional

<a name="v1.0.11"></a>
## [v1.0.11] - 2023-02-07
Changed
- Replaced `nutanix` user with the new one
- Locked `nutanix` user

<a name="unreleased"></a>
## [Unreleased]

<a name="v1.0.10"></a>
## [v1.0.10] - 2022-07-20
Changed
- Simplified the Ansible module

<a name="v1.0.9"></a>
## [v1.0.9] - 2022-07-20
Changed
- Ansible Module now only runs ansible code when its actually changed

<a name="v1.0.8"></a>
## [v1.0.8] - 2021-10-26
Changed
- Ansible Module now creates backup of existing ansible code

<a name="v1.0.7"></a>
## [v1.0.7] - 2021-10-20
Changed
- Ansible now has runtime selection and random_num generator on every run`

<a name="v1.0.6"></a>
## [v1.0.6] - 2021-10-11
Changed
- Ansible now deletes existing ansible code folder on module run`

<a name="v1.0.5"></a>
## [v1.0.5] - 2021-06-08
Added
- Triggers now detect when there are any ansible environment changes

<a name="v1.0.4"></a>
## [v1.0.4] - 2021-06-08
Added
- Updated ramdom string resource to exclude special and numbers

<a name="v1.0.3"></a>

## [v1.0.3] - 2021-06-08

Added
- Bug fix for step of backup ansible folder

<a name="v1.0.2"></a>
## [v1.0.2] - 2021-06-08

Added
- Added step backup ansible folder

<a name="v1.0.1"></a>
## [v1.0.1] - 2021-06-03

Added
- Added priority_count env variable for getting count.index in ansible

<a name="v1.0.0"></a>
## [v1.0.0] - 2021-06-01

Added
- Initial version of ansible module
