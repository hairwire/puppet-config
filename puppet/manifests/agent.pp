class puppet::agent {
  include puppet

  package { "puppet": provider => gem }

  case $operatingsystem {
    Darwin: {
      # Do nothing special here
    }
  
    default: {
      file { "/etc/puppet/puppet.conf":
        owner   => root,
        group   => root,
        mode    => 0755,
        ensure  => present,
        source  => "puppet:///modules/puppet/puppet-agent.conf",
        require => Package["puppet"];
      }
    }
  }
}
