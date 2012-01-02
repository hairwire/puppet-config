class puppet::agent {
  include puppet

  file { "/etc/puppet/puppet.conf":
    owner   => root,
    group   => root,
    mode    => 0755,
    ensure  => present,
    source  => "puppet:///modules/puppet/puppet-agent.conf",
    require => Package["puppet"];
  }
}
