# [*docroot*]           - The document root
# [*vhost_name*]        - The vhost_name parameter fed to the vhost. Usually an IP address.
# [*vhost_server_name*] - The name of the vhost resource. can be www.whatever.com, a friendly name, or the same as vhost_name
# [*app_archive*]       - What version of wordpress to install.
# [*app_install_dir*]   - Where wordpress should live inside the parent directory. USUALLY this is 'wordpress'
# [*config_mode*]       - Supported values here are apponly and dependent
# [*create_group*]      - Boolean. Whether or not to create the group.
# [*create_user*]       - Boolean. Whether or not to create the user.
# [*create_vhost*]      - Boolean. Whether or not to create the vhost.

define wordpress::app (
  $docroot,
  $vhost_name,
  $app_archive       = $wordpress::app_archive,
  $app_install_dir   = 'wordpress',
  $config_mode       = $wordpress::config_mode,
  $create_group      = false,
  $create_user       = false,
  $create_vhost      = false,
  $db_host           = undef,
  $db_name           = undef,
  $db_password       = undef,
  $db_user           = undef,
  $port              = '80',
  $serveraliases     = undef,
  $site_hash         = fqdn_rand(100000000000000000000000000000000,$db_name),
  $vhost_options     = ['Indexes','FollowSymLinks','MultiViews'],
  $vhost_override    = ['None'],
  $vhost_priority    = undef,
  $vhost_server_name = undef,
  $wp_install_parent = $docroot,
  $wp_group          = undef,
  $wp_owner          = undef,
  ){
  validate_bool($create_group)
  validate_bool($create_user)
  validate_bool($create_vhost)
  validate_re($docroot, '/$')
  validate_re($wp_install_parent,'/$')
  if $create_group {
    #if we are saying we'd like to create the group, we must provide the group to create.
    validate_string($wp_group)
  }
  #this will automate the:
  #- creation of a vhost through the apache module
  #- deployment of the wordpress content from the local archive.
  #- customization of templated configs
  case $config_mode {
    dependent:{
      $supported_dbhosts = ['localhost', '127.0.0.1']
      validate_re($db_host,$supported_dbhosts, 'In dependent mode, the wordpress module only supports the values \'localhost\', and \'127.0.0.1\' for $db_host. Please either use the apponly mode, or change the db_host to a supported local value.')
      #we should generate the db
      include mysql, mysql::server
      mysql::db { $db_name:
        user     => $db_user,
        password => $db_password,
        host     => $db_host,
      } -> File[$wp_install_parent]
    }#end dependent case
    default:{
      #do an app-only install
      include apache
    }
  }#end config mode case
  if !$wp_owner {#We were not handed the user.
    #Assume we're using the apache user, and it already exists
    include apache::params
    $local_wp_owner  = $apache::params::user
  } else {#we have a user
    $local_wp_owner = $wp_owner
    if $create_user {
      #we should create the user
      user { $local_wp_owner:
        ensure  => 'present',
        comment => "${name}_wpuser",
        home    => $docroot,
        shell   => '/dev/null',
      } -> File[$wp_install_parent]
    }#end create_user
  }#end wp_owner defined
  if !$wp_group {#We were not handed the group.
    #Assume we're using the apache group, and it already exists
    include apache::params
    $local_wp_group = $apache::params::group
  } else {
    $local_wp_group = $wp_group
    if $create_group {
      group { $local_wp_group:
        ensure  => 'present',
      } -> File[$wp_install_parent]
    }#end create_group
  }#end wp_group defined

  if ($create_user and $create_group){
    #if we're creating the user and the group, the user resource should come first
    if ($wp_group and $wp_owner) {
        User[$wp_owner] -> Group[$wp_group]
    }
  }

  include apache::params
  File {
    backup  => false,
    group   => $local_wp_group,
    mode    => '0644',
    owner   => $local_wp_owner,
    require => Package[$apache::params::apache_name]
  }
  Exec {
    cwd       => $wp_install_parent,
    group     => $local_wp_group,
    logoutput => 'on_failure',
    path      => ['/bin','/sbin','/usr/bin','/usr/sbin'],
    require   => Package[$apache::params::apache_name],
    user      => $local_wp_owner,
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
  file {"${name}_wordpress_uploads":
    ensure      => directory,
    path        => "${wp_install_parent}/${app_install_dir}/wp-content/uploads",
    mode        => '0775',
    group       => $apache::params::group,
    require     => Exec["${name}_extract_installer"],
    subscribe   => Exec["${name}_extract_installer"],
  }
  exec {"${name}_extract_installer":
    command      => "unzip -o ${wp_install_parent}/setup_files/${app_archive} -d ${wp_install_parent}",
    notify       => File["${name}_wordpress_uploads"],
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
    refreshonly  => true,
  }
  if $app_install_dir != 'wordpress' {
    #we need to move the wordpress dir to the expected path before the extractions.
    if (($create_vhost) and (( $docroot == "${wp_install_parent}${app_install_dir}") or ( $docroot == "${wp_install_parent}${app_install_dir}/"))) {
      #the vhost docroot and our expected path are the same. move the contents of the dir, then remove the original dir.
      exec {"${name}_move_wordpress_install":
        before       => [Exec["${name}_extract_themes","${name}_extract_plugins"],File["${name}_wordpress_uploads"]],
        command      => "/bin/mv ${wp_install_parent}wordpress/* ${wp_install_parent}${app_install_dir}/&&/bin/rm -rf ${wp_install_parent}wordpress",
        path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
        refreshonly  => true,
        require      => [File[${wp_install_parent}${app_install_dir}],Exec["${name}_extract_installer"]],
        subscribe    => Exec["${name}_extract_installer"],
      }
    } else {
      exec {"${name}_move_wordpress_install":
        before       => Exec["${name}_extract_themes","${name}_extract_plugins"],
        command      => "/bin/mv ${wp_install_parent}wordpress ${wp_install_parent}${app_install_dir}",
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
  if $create_vhost {#we should create the vhost
    if $vhost_server_name {
      #we gave the site a real name
      $sitename = $vhost_server_name
    }else {
      $sitename = "${name}_vhost"
    }
    include apache, apache::params
    Package[$apache::params::apache_name] ->
    apache::vhost{$sitename:
      port           => $port,
      docroot        => $docroot,
      docroot_owner  => $local_wp_owner,
      docroot_group  => $local_wp_group,
      options        => $vhost_options,
      override       => $vhost_override,
      priority       => $vhost_priority,
      vhost_name     => $vhost_name,
      serveraliases  => $serveraliases,
    }
  }
}#end defined type
