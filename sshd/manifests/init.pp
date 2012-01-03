class sshd
{
  # For Solaris:
  #
  #  packages network/ssh SUNWuiu8
  #
  #  Edit =/etc/ssh/sshd_config=:
  #  PermitRootLogin without-password
  #
  #  Edit =/etc/default/login=, and comment out this line:
  #  #CONSOLE =/dev/login
  #
  #  Execute:
  #  rolemod -K type=normal root
  case $operatingsystem {
    centos: {
      include centos
      $ssh_packages = ["openssh", "openssh-server", "openssh-clients"]
    }
    fedora: { $ssh_packages = ["openssh", "openssh-server", "openssh-clients"] }
    default: { $ssh_packages = ["openssh", "openssh-server", "openssh-clients"] } 
  }

  package { $ssh_packages: ensure => installed }

  firewall::rule_tmpl { sshd: }

  file { "/root/.ssh":
    owner   => "root",
    group   => "root",
    mode    => 0700,
    type    => directory,
    ensure  => directory,
    require => User[admin];
  }

  file { "/root/.ssh/authorized_keys":
    owner   => "root",
    group   => "root",
    mode    => 0600,
    ensure  => present,
    source  => "puppet:///modules/sshd/authorized_keys",
    require => File["/root/.ssh"];
  }

  file { "/etc/ssh/sshd_config":
    owner   => "root",
    group   => "root",
    mode    => 0600,
    ensure  => present,
    source  => "puppet:///modules/sshd/sshd_config",
    notify  => Service[sshd],
    require => Package[openssh-server];
  }

  service { sshd:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package[openssh-server];
  }

  nagios::target::service { sshd: }

  nagios::service { check_ssh: }

  tcpwrapper { sshd: allow => "ALL" }
}
