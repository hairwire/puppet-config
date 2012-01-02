# /etc/puppet/manifests/nodes.pp

node default {
}

node puppet {                   # this is the puppetmaster node
  exec { "say hello":
    command => "/bin/echo Hello world";
  }
}
