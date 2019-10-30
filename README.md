
# network_device_core

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with network_device_core](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with network_device_core](#beginning-with-network_device_core)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - User documentation](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Deprecation - This module's development status](#deprecation)

## Description
The functionality in this module has been deprecated and superseded by the puppetlabs/cisco_ios module. Please use that module instead.

Manage aspects of a given router or switch.

## Setup

### Beginning with network_device_core

To set the interface for a router or switch:
```
interface { "resource title":
  ensure => no_shutdown,
  device_url => 'ssh://user:pass:enable@host/',
  speed => auto,
  dupliex => auto,
  provider => cisco,
}
```

To manage a connected router:
```
router { 'resource title':
  url => 'telnet://user:pass:enable@host/',
}
```

To manage the vlan on a router or switch:
```
vlan { 'resource title':
  ensure => present,
  device_url => 'ssh://user:pass:enable@host/',
  provider => cisco,
}
```

## Usage

The functionality in this module has been deprecated and superseded by the puppetlabs/cisco_ios module. Please use that modules instead.

For details on usage, please see the puppet docs on [interface](https://puppet.com/docs/puppet/latest/types/interface.html), [router](https://puppet.com/docs/puppet/latest/types/router.html), and [vlan](https://puppet.com/docs/puppet/latest/types/vlan.html).


## Reference

Please see REFERENCE.md for the reference documentation.

This module is documented using Puppet Strings.

For a quick primer on how Strings works, please see [this blog post](https://puppet.com/blog/using-puppet-strings-generate-great-documentation-puppet-modules) or the [README.md](https://github.com/puppetlabs/puppet-strings/blob/master/README.md) for Puppet Strings.

To generate documentation locally, run
```
bundle install
bundle exec puppet strings generate ./lib/**/*.rb
```
This command will create a browsable `\_index.html` file in the `doc` directory. The references available here are all generated from YARD-style comments embedded in the code base. When any development happens on this module, the impacted documentation should also be updated.


## Deprecation

When the `network_device` types were removed from Puppet in Puppet Platform 6 and extracted to this module they were effectively deprecated and are now no longer under active develepment.

This repository has been archived, so you can still fork it and use the code. If you need help or have questions about this module, please join our [Community Slack](https://slack.puppet.com/).
