define wordpress::app (
  $docroot,
  $vhost_name,
  $app_archive       = $wordpress::app_archive,
  $app_install_dir   = 'wordpress',
  $config_mode       = $wordpress::config_mode,
  $create_group      = 'false',
  $create_user       = 'false',
  $create_vhost      = 'false',
  $db_host           = undef,
  $db_name           = undef,
  $db_password       = undef,
  $db_user           = undef,
  $port              = '80',
  $serveraliases     = undef,
  $site_hash         = fqdn_rand(100000000000000000000000000000000,$db_name),
  $vhost_priority    = undef,
  $vhost_server_name = undef,
  $wp_install_parent = $docroot,
  $wp_group          = 'undef',
  $wp_owner          = 'undef',
  $wp_owner_ssh_key  = 'undef',
  $wp_owner_ssh_name = 'undef',
  $wp_owner_ssh_opts = 'undef',
  $wp_owner_ssh_type = 'undef',
  ) {
  #this will automate the:
  #- creation of a vhost through the apache module
  #- deployment of the wordpress content from the local archive.
  #- customization of templated configs
  case $config_mode {
    dependent: {
      case $db_host {
        #we should only do things if the db_host is local
        /[[lL][oO][cC][aA][lL][hH][oO][sS][tT]|127.0.0.1]/: {
          #we should generate the db
          include mysql, mysql::server
          mysql::db { $db_name:
            user     => $db_user,
            password => $db_password,
            host     => $db_host,
          } -> File["${name}_wp_install_parent"]
        }
        default: {
          notify "for $::{fqdn} wordpress::config_mode has a value of dependent. The specified database is $db_host. Expecting '127.0.0.1' or 'localhost'."
        }
      }#end db_host case
    }#end dependent case
    default: {
      #do nothing. app-only install
    }
  }#end config mode case
  if !$wp_owner {#We were not handed the user.
    #Assume we're using the apache user, and it already exists
    include apache::params
    $wp_owner = $apache::params::user
  } else {#we have a user
      if $wp_owner_ssh_key {
        #We are not using the Apache user, and we have an ssh key
        #We should create it.
        ssh_authorized_key { "${wp_owner}_sshkey":
          ensure   => 'present',
          name     => $wp_owner_ssh_name,
          key      => $wp_owner_ssh_key,
          options  => $wp_owner_ssh_opts,
          type     => $wp_owner_ssh_type,
          user     => $wp_owner,
        }
      }
      case $create_user {
        /[tT][rR][uU][eE]/:{#we should create the user
          user { $wp_owner:
            ensure  => 'present',
            comment => "${name} wpuser",
            home    => $docroot,
            shell   => '/dev/null',
          } -> File[$wp_install_parent]
        }
        /[fF][aA][lL][sS][eE]/: {#user created elsewhere. do nothing
        }
        default: {
          fail "$::{fqdn} got unexpected value of \"$create_user\" for create_user. expecting true or false"
        }
      }#end create_user case
  }#end wp_owner defined

  if !$wp_group {#We were not handed the group.
    #Assume we're using the apache group, and it already exists
    include apache::params
    $wp_group = $apache::params::group
  } else {
      case $create_group {
        /[tT][rR][uU][eE]/:{#we should create the group
          group { $wp_group:
            ensure  => 'present',
          } -> File[$wp_install_parent]
        }
        /[fF][aA][lL][sS][eE]/: {#group created elsewhere. do nothing
        }
        default: {
          fail "$::{fqdn} got unexpected value of \"$create_group\" for create_group. expecting true or false"
        }
      }#end create_user case
  }#end wp_group defined

  File {
    owner  => $wp_owner,
    group  => $wp_group,
    mode   => '0644',
  }
  Exec {
    path      => ['/bin','/sbin','/usr/bin','/usr/sbin'],
    cwd       => $wp_install_parent,
    logoutput => 'on_failure',
    user      => $wp_owner,
    group     => $wp_group,
  }
  if ((!$create_vhost) or ($wp_install_parent != $docroot))  {
    #if we're creating this directory via apache, no need to do so here.
    file {$wp_install_parent:
      ensure  =>  directory,
      before  =>  File["${name}_setup_files_dir"]
    }
  }
  file {"${name}_setup_files_dir":
    ensure  =>  directory,
    path    =>  "${wp_install_parent}/setup_files",
    require =>  File[$wp_install_parent],
    before  =>  File["${name}_php_configuration","${name}_themes","${name}_plugins","${name}_installer","${name}_htaccess_configuration"],
  }
  file {"${name}_installer":
    ensure  =>  file,
    path    =>  "${wp_install_parent}/setup_files/${app_archive}",
    notify  =>  Exec["${name}_extract_installer"],
    source  =>  "puppet:///modules/wordpress/${app_archive}";
  }
  file {"${name}_php_configuration":
    ensure     =>  file,
    path       =>  "${wp_install_parent}/wp-config.php",
    content    =>  template('wordpress/wp-config.erb'),
    subscribe  =>  Exec["${name}_extract_installer"],
  }
  file {"${name}_htaccess_configuration":
    ensure     =>  file,
    path       =>  "${wp_install_parent}/.htaccess",
    source     =>  'puppet:///modules/wordpress/.htaccess',
    subscribe  =>  Exec["${name}_extract_installer"],
  }
  file {"${name}_themes":
    ensure     => directory,
    path       => "${wp_install_parent}/setup_files/themes",
    source     => 'puppet:///modules/wordpress/themes/',
    recurse    => true,
    purge      => true,
    ignore     => '.svn',
    notify     => Exec["${name}_extract_themes"],
    subscribe  => Exec["${name}_extract_installer"],
  }
  file {"${name}_plugins":
    ensure     => directory,
    path       => "${wp_install_parent}/setup_files/plugins",
    source     => 'puppet:///modules/wordpress/plugins/',
    recurse    => true,
    purge      => true,
    ignore     => '.svn',
    notify     => Exec["${name}_extract_plugins"],
    subscribe  => Exec["${name}_extract_installer"],
  }
  exec {"${name}_extract_installer":
    command      => "unzip -o ${wp_install_parent}/setup_files/${app_archive} -d ${wp_install_parent}",
    refreshonly  => true,
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin']
  }
  if $app_install_dir != 'wordpress' {
    #we need to move the wordpress dir to the expected path before the extractions.
    if (($create_vhost) and (( "$docroot" == "${wp_install_parent}${app_install_dir}") or ( "$docroot" == "${wp_install_parent}${app_install_dir}/"))) {
      #the vhost docroot and our expected path are the same. move the contents of the dir, then remove the original dir.
      exec {"${name}_move_wordpress_install":
        before       => Exec["${name}_extract_themes","${name}_extract_plugins"],
        command      => "/bin/mv ${wp_install_parent}/wordpress/* ${wp_install_parent}/${app_install_dir}/&&/bin/rm -rf ${wp_install_parent}/wordpress",
        path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
        refreshonly  => true,
        require      => Exec["${name}_extract_installer"],
        subscribe    => Exec["${name}_extract_installer"],
      }
    } else {
      exec {"${name}_move_wordpress_install":
        before       => Exec["${name}_extract_themes","${name}_extract_plugins"],
        command      => "/bin/mv ${wp_install_parent}/wordpress ${wp_install_parent}/${app_install_dir}",
        path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
        refreshonly  => true,
        require      => Exec["${name}_extract_installer"],
        subscribe    => Exec["${name}_extract_installer"],
      }
    }
  }
  exec {"${name}_extract_themes":
    command      => "/bin/sh -c 'for themeindex in `ls ${wp_install_parent}/setup_files/themes/*.zip`; do unzip -o \$themeindex -d ${wp_install_parent}/${app_install_dir}/wp-content/themes/; done'",
    cwd          => "${wp_install_parent}/setup_files/themes",
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
    refreshonly  => true,
    subscribe    => File["${name}_themes"];
  }
  exec {"${name}_extract_plugins":
    command      => "/bin/sh -c 'for pluginindex in `ls ${wp_install_parent}/setup_files/plugins/*.zip`; do unzip -o \$pluginindex -d ${wp_install_parent}/${app_install_dir}/wp-content/plugins/; done'",
    cwd          => "${wp_install_parent}/setup_files/plugins",
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
    refreshonly  => true,
    subscribe    => File["${name}_plugins"];
  }
  case $create_vhost {
    /[tT][rR][uU][eE]/:{#we should create the vhost
      if $vhost_server_name {
        #we gave the site a real name
        $sitename = $vhost_server_name
      }else {
        $sitename = "${name}_vhost"
      }
      include apache
      apache::vhost{$sitename:
        port           => $port,
        docroot        => $docroot,
        docroot_owner  => $wp_owner,
        docroot_group  => $wp_group,
        priority       => $vhost_priority,
        vhost_name     => $vhost_name,
        serveraliases  => $serveraliases,
      }
    }
    /[fF][aA][lL][sS][eE]/: {#vhost created elsewhere. do nothing
    }
    default: {
      fail "$::{fqdn} got unexpected value of \"$create_vhost\" for create_vhost. expecting true or false"
    }
  }
}#end defined type

