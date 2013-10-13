#!/usr/bin/env rspec
require 'spec_helper'
describe 'wordpress::standalone', :type => :class do
  describe 'On a RedHat 6 OS' do
    let :facts do {
      :concat_basedir         => '/dne',
      :lsbmajdistrelease      => '6',
      :network_primary_ip     => '1.2.3.4',
      :operatingsystemrelease => '6.1',
      :osfamily               => 'RedHat',
    } end
    let (:params) do {
      'app_archive'    => 'wordpress-3.5.2.zip',
      'app_child_dir'  => 'wordpress',
      'app_hash'       => {
        'wordpressvhost' => {
          'create_group'      => true,
          'create_user'       => true,
          'create_vhost'      => true,
          'db_host'           => 'localhost',
          'db_name'           => 'wordpressdb',
          'db_password'       => 'wpDBUpa55word',
          'db_user'           => 'wordpressdbuser',
          'docroot'           => '/var/www/wordpress/wordpress',
          'port'              => '80',
          'serveraliases'     => "$::hostname",
          'vhost_name'        => "$::network_primary_ip",
          'wp_install_parent' => '/var/www/wordpress/',
          'wp_owner'          => 'wordpress',
          'wp_group'          => 'wordpress'
        }},
      'app_parent'     => '/opt/',
      'mysql_version'  => '5.5',
      'package_ensure' => 'present',
    } end
    describe 'mysql service' do
      context 'when mysql_version is 5.1' do
        it do
          params.merge!({'mysql_version' => '5.1'})
          should contain_service('mysqld')
        end
      end
      context "when mysql_version is 5.5" do
        it {should contain_service('mysql')}
      end
    end
    it 'should contain php packages' do
      should contain_package('php')
      should contain_package('php-mysql')
    end
    context 'When mysql_version is not 5.1 or 5.5' do
      it do
        params.merge!({'mysql_version' => 'BOGON',
          'app_parent' => '/tmp'})
        expect { subject }.to raise_error(Puppet::Error, /unsupported value of "BOGON" found for mysql_version./)
      end
    end
  end
  describe 'On a RedHat 5 OS' do
    let :facts do {
      :concat_basedir         => '/dne',
      :lsbmajdistrelease      => '5',
      :network_primary_ip     => '1.2.3.4',
      :operatingsystemrelease => '5.9',
      :osfamily               => 'RedHat',
    } end
    let (:params) do {
      'app_archive'    => 'wordpress-3.5.2.zip',
      'app_child_dir'  => 'wordpress',
      'app_hash'       => {
        'wordpressvhost' => {
          'create_group'      => true,
          'create_user'       => true,
          'create_vhost'      => true,
          'db_host'           => 'localhost',
          'db_name'           => 'wordpressdb',
          'db_password'       => 'wpDBUpa55word',
          'db_user'           => 'wordpressdbuser',
          'docroot'           => '/var/www/wordpress/wordpress',
          'port'              => '80',
          'serveraliases'     => "$::hostname",
          'vhost_name'        => "$::network_primary_ip",
          'wp_install_parent' => '/var/www/wordpress/',
          'wp_owner'          => 'wordpress',
          'wp_group'          => 'wordpress'
        }},
      'app_parent'     => '/opt/',
      'mysql_version'  => '5.5',
      'package_ensure' => 'present',
    } end
    describe 'module files'do
      [
       'wordpress_htaccess_configuration',
       'wordpress_installer',
       'wordpress_php_configuration',
       'wordpress_plugins',
       'wordpress_setup_files_dir',
       'wordpress_sql_script',
       'wordpress_themes',
       'wordpress_vhost',
       '/var/www/wordpress/',
       '/var/www/wordpress/wordpress',
       '/var/www/wordpress/wordpress/wp-content/uploads',
       ].each do |wp_files|
        it "should contain #{wp_files}" do
          should contain_file(wp_files)
        end
      end
    end
    describe 'removed packages' do
      ['php','php-common'].each do |nuked|
        it "should remove #{nuked} if present" do
          should contain_package(nuked).with('ensure'=>'absent')
        end
      end
    end
    describe 'module packages' do
      ['php53', 'MySQL-server', 'MySQL-client', 'MySQL-shared-compat', 'MySQL-shared','unzip','php53-mysql','httpd'].each do |wp_pkg|
        it "should contain package #{wp_pkg}" do
          should contain_package(wp_pkg)
        end
      end
    end
    describe 'module execs' do
      ['wordpress_extract_installer','wordpress_extract_themes','wordpress_extract_plugins','create_schema','grant_privileges'].each do |wp_exec|
        it "should contain #{wp_exec}" do
          should contain_exec(wp_exec)
        end
      end
    end
    describe 'mysql service' do
      ['5.0','5.1'].each do |mysqlversion|
        context "when mysql_version is #{mysqlversion}" do
          it do
            params.merge!({'mysql_version' => mysqlversion})
            should contain_service('mysqld')
          end
        end
      end
      context "when mysql_version is 5.5" do
        it {should contain_service('mysql')}
      end
    end
    describe 'input validation tests' do
      context 'when wp_install_parent is present, and does not end with a trailing /' do
        it do
          params.merge!({'app_hash' => {
            'wordpressvhost' => {
              'wp_install_parent' =>  'foo'
            }
          }})
          expect { subject }.to raise_error(Puppet::Error, /does not match "\/\$"/)
        end
      end
      context 'when wp_install_parent is not present, and app_parent does not end with a trailing / ' do
        it do
          params.merge!({'app_hash' => {'wordpressvhost' => {}},
            'app_parent' => '/tmp'})
          expect { subject }.to raise_error(Puppet::Error, /does not match "\/\$"/)
        end
      end
      context 'When app_child_dir is set to somethign other than \'wordpress\'' do
        it do
          params.merge!({'app_child_dir' => 'BOGON',})
          expect { subject }.to raise_error(Puppet::Error, /In standalone mode, the only supported value of app_child_dir at this time is \'wordpress\'/)
        end
      end
      context 'When mysql_version is not 5.0, 5.1, or 5.5' do
        it do
          params.merge!({'mysql_version' => 'BOGON',
            'app_parent' => '/tmp'})
          expect { subject }.to raise_error(Puppet::Error, /unsupported value of "BOGON" found for mysql_version./)
        end
      end
    end
    describe 'user and group tests' do
      context 'when create_user is true' do
        it do
          params.merge!({'app_hash' => {
            'wordpressvhost' => {
              'create_user'       => true,
              'wp_owner'          => 'wordpress'
            }},
          })
          should contain_user('wordpress')
        end
      end
      context 'when create_user is false' do
        it do
          params.merge!({'app_hash' => {
            'wordpressvhost' => {
              'create_user'       => false,
            }},
          })
          should_not contain_user('wordpress')
        end
      end
      context 'when create_group is true' do
        it do
          params.merge!({'app_hash' => {
            'wordpressvhost' => {
              'create_group'      => true,
              'wp_group'          => 'wordpress'
            }},
          })
          should contain_group('wordpress')
        end
      end
      context 'when create_group is false' do
        it do
          params.merge!({'app_hash' => {
            'wordpressvhost' => {
              'create_group'      => false,
            }},
          })
          should_not contain_group('wordpress')
        end
      end
    end
  end
end
