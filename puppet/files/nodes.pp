# /etc/puppet/manifests/nodes.pp

node default {
  include puppet::agent
  include ssh::server
}

node puppet {                   # this is the puppetmaster node
  include puppet::master
  include ssh::server
}

import '/etc/puppet/site/modules/nodes.pp'

# nodes.pp ends here
