# /etc/puppet/manifests/nodes.pp

node default {
  include puppet::agent
}

node puppet inherits default {  # this is the puppetmaster node
  include puppet::master
}

# nodes.pp ends here
