Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

class ubuntu {
    group { "puppet": ensure => "present"; } ->
    group { "vagrant": ensure => "present"; } ->
    user { "vagrant": ensure => "present"; } ->
    file { "/home/vagrant/bin":
        ensure  => "directory",
        owner   => "vagrant",
        group   => "vagrant",
        mode    => "755",
    }

    # update once
    exec {"apt-get-update":
        creates => "/updated",
        command => "/usr/bin/apt-get update && touch /updated",
    }
}

class apache {

  $config = '/etc/apache2/sites-available/default'
  $serverName = 'api'

  exec { 'apt-get update':
    command => '/usr/bin/apt-get update'
  }

  package { "apache2":
    ensure => present,
  }

  exec { "servername":
    unless  => "/bin/grep '^ServerName' /etc/apache2/apache2.conf",
    command => "/bin/echo ServerName $serverName >> /etc/apache2/apache2.conf",
    require => Package["apache2"],
  } ->
  
  exec { "mod-rewrite":
    unless => "/bin/ls /etc/apache2/mods-enabled/rewrite*",
    command => "/usr/sbin/a2enmod rewrite",
    require => Package["apache2"],
  } ->
 
  exec { "document-root-1":
    unless => "/bin/sed -n '4 p' $config | /bin/grep 'all'",
    command => "/bin/sed -i '4 s/www/app/' $config",
    require => Package["apache2"],
  } ->
 
  exec { "document-root-2":
    unless => "/bin/sed -n '9 p' $config | /bin/grep 'all'",
    command => "/bin/sed -i '9 s/www/app/' $config",
    require => Package["apache2"],
  } ->
  
  exec { "allow-override":
    unless => "/bin/sed -n '11 p' $config | /bin/grep 'AllowOverride All'",
    command => "/bin/sed -i '11 s/None/All/' $config",
    require => Package["apache2"],
  } ->
  
  user { "www-data":
    groups => ["vagrant"],
    require => Package["apache2"],
  } ->
  
  file { "/var/app":
    ensure => link,
    target => "/vagrant/src/app",
    require => Package["apache2"],
  } ->

  service { "apache2":
    ensure => running,
    require => Package["apache2"],
  }

}

class mysql {

    $mysql_password = "vagrant"
    $database = "app"
    $database_user = "app"
    $database_password = "app"

    package { "mysql-server": ensure => installed }

    service { "mysql":
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        require => Package["mysql-server"],
    } ->

    exec { "mysql-set-password":
        subscribe => Service["mysql"],
        unless => "/usr/bin/mysqladmin -uroot -p${mysql_password} status",
        command => "/usr/bin/mysqladmin -uroot password ${mysql_password}",
        require => Package["mysql-server"],
    } ->

    exec { "mysql-create-db":
      unless  => "/usr/bin/mysql -u${database_user} -p${database_password} ${database}",
      command => "/usr/bin/mysql -uroot -p$mysql_password -e \"create database ${database}; grant all on ${database}.* to ${database_user}@localhost identified by '$database_password';\"",
      require => Package["mysql-server"],
    } 
 
}

class php {
    $php = ["php5-cli", "php5-mysql", "libapache2-mod-php5", "php-pear"]
    $include = '.:/usr/share/php:/vagrant/src/cakephp/lib/'
    $cliini = '/etc/php5/cli/php.ini'
    $apacheini = '/etc/php5/apache2/php.ini'

    package { $php: ensure => "installed" }

    exec { "cli-include-path":
        subscribe => Package["php5-cli"],
        unless => "/bin/grep -q ^include_path $cliini",
        command => "/bin/echo include_path = $include >> $cliini",
        notify  => Service["apache2"],
    } ->
    exec { "apache-include-path":
        unless => "/bin/grep -q ^include_path $apacheini",
        command => "/bin/echo include_path = $include >> $apacheini",
        notify  => Service["apache2"],
    } ->
    exec { "mod-php":
        unless => "/bin/ls /etc/apache2/mods-enabled/php5*",
        command => "/usr/sbin/a2enmod php5",
        notify  => Service["apache2"],
    }
    # ->
    #exec { "phpunit":
    #    creates => "/usr/bin/phpunit",
    #    command => "/usr/bin/pear upgrade pear && \
    #                /usr/bin/pear channel-discover pear.phpunit.de && \
    #                /usr/bin/pear channel-discover components.ez.no && \
    #                /usr/bin/pear channel-discover pear.symfony-project.com && \
    #                /usr/bin/pear install --alldeps phpunit/PHPUnit",
    #    require => Package["php-pear"],
    #}
}

class misc {
    $niceties = ["htop", "sudo", "vim", "curl", "cowsay", "figlet",
            "inotify-tools"]
    package { $niceties: ensure => "installed" }

    file { "/usr/local/bin/cowsay":
        ensure => link,
        target => "/usr/games/cowsay",
        require => Package['cowsay'],
    }
}

class cakephpbox {
    class { "ubuntu": }
    class { "apache": }
    class { "mysql":  require => Exec['apt-get-update'], }
    class { "php": require => Exec['apt-get-update'], }
    class { "misc": require => Exec['apt-get-update'], }
}

include cakephpbox
