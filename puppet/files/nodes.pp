# /etc/puppet/manifests/nodes.pp

node default {
  include puppet::agent
}

node puppet {                   # this is the puppetmaster node
  include puppet::master
}

import '/etc/pupet/site/modules/nodes.pp'

# nodes.pp ends here
