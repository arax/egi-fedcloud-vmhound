[![Build Status](https://secure.travis-ci.org/arax/egi-fedcloud-vmhound.png)](http://travis-ci.org/arax/egi-fedcloud-vmhound)
[![Dependency Status](https://gemnasium.com/arax/egi-fedcloud-vmhound.png)](https://gemnasium.com/arax/egi-fedcloud-vmhound)
[![Gem Version](https://fury-badge.herokuapp.com/rb/egi-fedcloud-vmhound.png)](https://badge.fury.io/rb/egi-fedcloud-vmhound)
[![Code Climate](https://codeclimate.com/github/arax/egi-fedcloud-vmhound.png)](https://codeclimate.com/github/arax/egi-fedcloud-vmhound)

# EGI FedCloud VMHound

A proof-of-concept utility for locating VM instances in EGI Federated Cloud.

## Installation
### Dependencies
* __Debian-based__
```bash
$ sudo apt-get install ruby ruby-dev libxml2 build-essential
```
* __RHEL-based__
```bash
$ sudo yum install ruby ruby-devel libxml2
```

### From RubyGems.org
```bash
$ gem install egi-fedcloud-vmhound
$ egi-fedcloud-vmhound help
```

### From Source
```bash
$ git clone https://github.com/arax/egi-fedcloud-vmhound.git
$ cd egi-fedcloud-vmhound
$ gem install bundler
$ bundle install
$ bundle exec bin/egi-fedcloud-vmhound help
```

## Usage
```bash
$ egi-fedcloud-vmhound help
Commands:
  egi-fedcloud-vmhound appuri URI      # Prints information based on the provided Appliance MPURI
  egi-fedcloud-vmhound help [COMMAND]  # Describe available commands or one specific command
  egi-fedcloud-vmhound ip IP_ADDRESS   # Prints information based on the provided IP address or IP address range
  egi-fedcloud-vmhound user ID         # Prints information based on the provided user identifier
```

```bash
$ egi-fedcloud-vmhound help user

$ USER_DN="/DC=cz/DC=cesnet-ca/O=CESNET/CN=John Doe"
$ egi-fedcloud-vmhound user $USER_DN
$ egi-fedcloud-vmhound user $USER_DN --format=plain
$ egi-fedcloud-vmhound user $USER_DN --format=json
```

```bash
$ egi-fedcloud-vmhound help appuri

$ MPURI="https://appdb.egi.eu/store/vo/image/ac34bc96-4d78-583a-b73b-a9102aeec206:403/"
$ egi-fedcloud-vmhound appuri $MPURI
$ egi-fedcloud-vmhound appuri $MPURI --format=plain
$ egi-fedcloud-vmhound appuri $MPURI --format=json
```

```bash
$ egi-fedcloud-vmhound help ip

$ IP_ADDRESS="192.168.5.0/24" # range or host IP
$ egi-fedcloud-vmhound ip $IP_ADDRESS
$ egi-fedcloud-vmhound ip $IP_ADDRESS --format=plain
$ egi-fedcloud-vmhound ip $IP_ADDRESS --format=json
```

## Contributing

1. Fork it ( https://github.com/arax/egi-fedcloud-vmhound/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
