class ssh::server inherits ssh
{
  case $operatingsystem {
    centos, fedora: {
      $ssh_service  = "sshd"
      $sshd_config  = "/etc/ssh/sshd_config"
      $ssh_packages = [ "openssh"
                      , "openssh-server"
                      , "openssh-clients" ]
    }

    Solaris: {
      $ssh_service  = "network/ssh"
      $sshd_config  = "/etc/ssh/sshd_config"
      $ssh_packages = [ "network/ssh"
                      , "network/ssh/ssh-key"
                      , "service/network/ssh"
                      , "SUNWuiu8" ]

      # On some Solaris systems, the following is necessary to allow root
      # logins:
      #  rolemod -K type=normal root

      exec { "allow non-console root logins":
        user    => root,
        command => "perl -i -pe 's/^CONSOLE/#CONSOLE/;' /etc/default/login",
        onlyif  => "grep '^CONSOLE' /etc/default/login";
      }
    }

    Darwin: {
      $ssh_service  = "sshd"
      $sshd_config  = "/etc/sshd_config"
      $ssh_packages = [ "openssh" ]
    }

    default: {
      $ssh_service  = "sshd"
      $sshd_config  = "/etc/ssh/sshd_config"
      $ssh_packages = [ "ssh" ]
    }
  }

  package { $ssh_packages: ensure => latest }

  file { "/root/.ssh":
    owner   => "root",
    group   => "root",
    mode    => 0700,
    type    => directory,
    ensure  => directory,
    require => User[admin];
  }

  exec { "permit root logins":
    user    => root,
    command => "perl -i -pe 's/^#?PermitRoot.*/PermitRootLogin without-password/;' $sshd_config",
    unless  => "grep '^PermitRootLogin without-password' $sshd_config";
  }

  service { sshd:
    name       => $ssh_service,
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package[$ssh_packages];
  }

  tcpwrapper::rule { sshd: allow => "ALL" }

  #nagios::target::service { sshd: }
  #nagios::service { check_ssh: }

  #firewall::rule_tmpl { sshd: }
}
