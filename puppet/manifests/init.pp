class puppet {
  user { puppet:
    home     => "/",
    shell    => "/usr/bin/false",
    ensure   => present;
  }

  case $operatingsystem {
    Darwin: {
      # Do nothing special here
    }

    default: {
      service { puppet:
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        subscribe  => File["/etc/puppet/puppet.conf"];
      }
    }
  }
  
  case $operatingsystem {
    centos: {
      file { "/etc/init.d/puppet":
        owner   => root,
        group   => root,
        mode    => 0755,
        ensure  => present,
        source  => "puppet:///modules/puppet/centos/puppet.init",
        require => Package["puppet"];
      }
  
      Service[puppet] {
        require => [ Package["puppet"], File["/etc/init.d/puppet"] ]
      }
    }
  
    Solaris: {
      file { "/etc/svc/profile/puppet.xml":
        owner   => root,
        group   => root,
        mode    => 0755,
        ensure  => present,
        source  => "puppet:///modules/puppet/solaris/puppet.xml",
        require => Package["puppet"];
      }
  
      exec { "install puppet.xml manifest":
        user    => root,
        command => "/usr/sbin/svccfg import /etc/svc/profile/puppet.xml",
        unless  => "/usr/sbin/svccfg list network/puppet | grep -q network/puppet",
        require => File["/etc/svc/profile/puppet.xml"];
      }
  
      Service[puppet] {
        name    => "network/puppet",
        require => [ Package["puppet"], Exec["install puppet.xml manifest"] ]
      }
    }
  
    Darwin: {
      # Do nothing special here
    }
  
    default: {
      Service[puppet] {
        require => Package["puppet"]
      }
    }
  }
}
