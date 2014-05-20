#Class: wordpress

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with wordpress](#setup)
    * [What wordpress affects](#what-wordpress-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with wordpress](#beginning-with-wordpress)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for contributing to the module](#development)

##Overview

This is the wordpress module.
This module supports:

* Standalone mode: no dependencies
* Dependent mode: leverage puppetlabs-apache and puppetlabs-mysql modules to configure the vhost and the database respectively
* App-only mode: utilize puppetlabs-apache to create vhost deploy tarball, configure wordpress configfile

##Setup

###What wordpress affects

* Wordpress configuration
* MySQL Database

###Setup Requirements

* puppet-network
* Dependent mode:
  * puppetlabs-mysql
  * puppetlabs-apache
  * concat

###Beginning with wordpress

* `include wordpress`

###Parameters

* **app_archive**: This should be the name of the zip file containing the wordpress version
* **config_mode**:
  * **standalone**: Assumes it's an island, installs everything minially and configures one instance of wordpress.
  * **dependent**: Assumes everthing is on one node. Depends on puppetlabs/apache and puppetlabs/mysql.
  * **apponly**: Only creates a vhost and deploys the app there. Depends on puppetlabs/apache.
* **app_hash**: This is the meat of the vhost/db config.
                Allows for the instantiation of multiple wp sites on one box.
    * **Elements in hash**:
      * **port**: TCP port apache vhost should listen on
      * **docroot**: The document root for the vhost
      * **db_name**: The name of the db wordpress will use
      * **db_user**: The mysql username wordpress will access the db via
      * **db_password**: The mysql password wordpress will access the db with
      * **db_host**: The host the db lives on (This module will only create a db if this is localhost|127.0.0.1)
      * **wp_install_parent**: The parent dir that wordpress will be extracted into *must end in a trailing slash*
      * **wp_owner**: The user account that owns wordpress. Defaults to apache's user
      * **wp_group**: The group that owns wordpress. Defaults to apache's group
      * **create_user**: true/false boolean
      * **create_group**: true/false boolean
      * **create_vhost**: true/false boolean
      * **vhost_name**: what the vhost should respond to
      * **serveraliases**: aliases the vhost should respond to
* **wordpress_app_parent**: This directory is the parent dir that wordpress_app_dir is a subdirectory of *must end in a trailing slash*
* **wordpress_mysql_version**: This is only relevant for standalone version to get package names right in case of non-standard versions of mysql
* **wordpress_package_ensure**: Ensure value for standalone packages. Supported values are present or latest

##Usage

###Example hiera keys

####Standalone mode:

     wordpress::app_archive: 'wordpress-3.5.2.zip'
     wordpress::app_dir: 'wordpress'
     wordpress::app_hash:
       wordpressvhost: {
        port:              '80',
        docroot:           '/var/www/wordpress/wordpress/',
        db_name:           'wordpressdb',
        db_user:           'wordpressdbuser',
        db_password:       'wpDBUpa55word',
        db_host:           'localhost',
        wp_install_parent: '/var/www/wordpress/',
         wp_owner:          'wordpress',
         wp_group:          'wordpress',
         vhost_name:        "%{::network_primary_ip}",
         serveraliases:     "%{::hostname}",
         create_user:       true,
         create_group:      true,
         create_vhost:      true
       }
     wordpress::app_parent: '/opt/'
     wordpress::config_mode: 'standalone'
     wordpress::mysql_version: '5.5'
     wordpress::package_ensure: 'present'

####Dependent mode

     wordpress::app_archive: 'wordpress-3.5.2.zip'
     wordpress::app_dir: 'wordpress'
     wordpress::app_hash:
       wordpressvhost: {
         port:              '80',
         docroot:           '/var/www/wordpress/wordpress/',
         db_name:           'wordpressdb',
         db_user:           'wordpressdbuser',
         db_password:       'wpDBUpa55word',
         db_host:           'localhost',
         wp_install_parent: '/var/www/wordpress',
         wp_owner:          'wordpress',
         wp_group:          'wordpress',
         vhost_name:        "%{::network_primary_ip}",
         serveraliases:     "%{::hostname}",
         create_user:       true,
         create_group:      true,
         create_vhost:      true
       }
     wordpress::app_parent: '/opt/'
     wordpress::config_mode: 'dependent'
     wordpress::mysql_version: '5.5'
     wordpress::package_ensure: 'present'

**NOTE**: If trying to use this module on RHEL 5 in dependent/apponly mode, you MUST use php53. This may require adjusting the php parameters of both mysql::php, apache, and apache::mod.

##Reference



####User/Group

       
####Directory and file declarations

####Execs

       #execs


####Parameters and OS case


####Package installs

       #all the variables are set. lets install the packages.
       #ensure unwanted php packages are removed on rh5.
       if $remove_php {
         package { ['php','php-common']:
           ensure => 'absent',
           before => Package[$php_pkg]
         }
       }
       package { $mysql_pkgs:
         ensure => $ensure
       } ->
       package { ['unzip',$php_pkg,$phpmysql_pkg]:
         ensure => $ensure,
       } ->
       package { $apache_pkg:
         ensure => $ensure,
       } -> Anchor['wordpress::package::end']
     }#end class



##Limitations

##Development

Wolf Noble <wolf@wolfspyre.om>
