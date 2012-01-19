class puppet::master {
  include puppet

  package { "puppet": provider => gem }
  
  file { "/etc/puppet/puppet.conf":
    owner   => root,
    group   => root,
    mode    => 0755,
    ensure  => present,
    content => template("puppet/puppet.conf.erb"),
    require => Package["puppet"];
  }
  
  file { "/etc/puppet/auth.conf":
    owner   => root,
    group   => root,
    mode    => 0755,
    ensure  => present,
    content => template("puppet/auth.conf.erb"),
    require => Package["puppet"];
  }
  
  file { "/etc/puppet/manifests/site.pp":
    owner   => root,
    group   => root,
    mode    => 0755,
    ensure  => present,
    source  => "puppet:///modules/puppet/site.pp",
    require => Package["puppet"];
  }
  
  file { "/etc/puppet/manifests/nodes.pp":
    owner   => root,
    group   => root,
    mode    => 0755,
    ensure  => present,
    source  => "puppet:///modules/puppet/nodes.pp",
    require => Package["puppet"];
  }
  
  package { "rack": provider => gem }
  package { "rails":
    # Rails 3.1 broke stored configs in Puppet 2.7.x, so for now the solution is
    # to install Rails 3.0.x.
    ensure   => '3.0.11',
    provider => gem,
    require  => Package["rack"];
  }
  
  service { mysqld:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true;
  }
  
  define mysql_database($user, $passwd, $host = "localhost") {
    exec { "create MySQL user $user":
      path    => "/usr/sbin:/usr/bin/:/sbin:/bin",
      user    => root,
      command => "sleep 30; mysql mysql -e \"CREATE USER $user@$host IDENTIFIED BY '$passwd';\"",
      unless  => "mysql mysql -e \"SELECT user FROM user WHERE user='$user'\" | grep $user",
      require => Service[mysqld];
    }
  
    exec { "create MySQL database $title":
      path    => "/usr/sbin:/usr/bin/:/sbin:/bin",
      user    => root,
      command => "mysql -e 'CREATE DATABASE $title'",
      unless  => "mysql -e 'SHOW DATABASES' | grep $title",
      require => Exec["create MySQL user $user"];
    }
  
    exec { "grant MySQL user $user":
      path        => "/usr/sbin:/usr/bin/:/sbin:/bin",
      user        => root,
      command     => "mysql -e \"GRANT ALL PRIVILEGES ON $title.* TO $user@$host IDENTIFIED BY '$passwd'\"",
      refreshonly => true,
      subscribe   => Exec["create MySQL database $title"],
      require     => Exec["create MySQL database $title"];
    }
  }
  
  #CREATE INDEX exported_restype_title ON resources(exported, restype, title(50));
  
  mysql_database { "puppet":
    user     => "puppet",
    passwd   => "puppet";
  }
  
  service { puppetmaster:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => File["/etc/puppet/puppet.conf"];
  }
  
  case $operatingsystem {
    centos: {
      file { "/etc/init.d/puppetmaster":
        owner   => root,
        group   => root,
        mode    => 0755,
        ensure  => present,
        source => "puppet:///modules/puppet/centos/puppetmaster.init";
      }
  
      $devel_pkgs = [ 'autoconf'
                    , 'automake'
                    , 'libtool'
                    , 'make'
                    , 'gcc'
                    , 'gcc-c++'
                    , 'glibc-devel'
                    , 'kernel-devel'
                    , 'rpm-build'
                    , 'rpm-devel'
                    , 'openssl-devel'
                    , 'readline-devel'
                    , 'zlib-devel'
                    ]
  
      package { $devel_pkgs: ensure => installed }
  
      $packages = [ "mysql-server", "mysql-devel.$architecture" ]
  
      package { $packages: ensure => installed }
  
      package { "mysql": provider => gem }
  
      # Building the mysql gem requires mysql-devel
      Package["mysql"] {
        require => [ Package["mysql-devel.$architecture"],
                     Package[$devel_pkgs] ]
      }
  
      Service[mysqld] {
        require => Package["mysql-server"]
      }
  
      Service[puppetmaster] {
        require => [ Package["puppet"], Service[mysqld],
                     File["/etc/init.d/puppetmaster"] ]
      }
    }
  
    Solaris: {
      file { "/etc/svc/profile/puppetmaster.xml":
        owner   => root,
        group   => root,
        mode    => 0755,
        ensure  => present,
        source  => "puppet:///modules/puppet/solaris/puppetmaster.xml",
        require => Package[puppet];
      }
  
      exec { "install puppetmaster.xml manifest":
        path    => "/usr/sbin:/usr/bin/:/sbin:/bin",
        user    => root,
        command => "svccfg import /etc/svc/profile/puppetmaster.xml",
        unless  => "svccfg list network/puppetmaster | grep network/puppetmaster",
        require => File["/etc/svc/profile/puppetmaster.xml"];
      }
  
      Service[puppetmaster] {
        name    => "network/puppetmaster",
        require => [ Package["puppet"], Service[mysqld],
                     Exec["install puppetmaster.xml manifest"] ]
      }
  
      $devel_pkgs = [ 'pkg:/file/gnu-coreutils'
                    , 'pkg:/developer/build/gnu-make'
                    , 'pkg:/developer/gcc-3'
                    , 'pkg:/developer/gnu-binutils'
                    , 'pkg:/system/library/math/header-math' ]
      
      package { $devel_pkgs:
        provider => pkg,
        ensure   => installed;
      }
      
      $packages = [ "mysql-51", "mysql-51/library" ]
      
      package { $packages:
        provider => pkg,
        ensure   => installed;
      }
  
      ## Building the mysql gem requires mysql-devel
      #package { "mysql": provider => gem }
      #Package["mysql"] {
      #  require => [ Package["mysql-51/library"], Package[$devel_pkgs] ]
      #}
  
      exec { "manually install mysql gem":
        path    => "/usr/sbin:/usr/bin/:/sbin:/bin",
        user    => root,
        command => "gem install -r --no-rdoc --no-ri mysql -- --with-mysql-dir=/usr/mysql --with-mysql-lib=/usr/mysql/lib --with-mysql-include=/usr/mysql/include",
        unless  => "gem list mysql | grep ^mysql",
        require => [ Package[$packages], Package[$devel_pkgs] ];
      }
  
      Service[mysqld] {
        name    => "database/mysql",
        require => Exec["manually install mysql gem"]
      }
    }
  
    default: {
      Service[puppetmaster] {
        require => [ Package["puppet"], Service[mysqld] ]
      }
    }
  }
}
