#!/usr/bin/env rspec
require 'spec_helper'
describe 'wordpress::dependent', :type => :class do
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
        'wp' => {
          'create_group'      => true,
          'create_user'       => true,
          'create_vhost'      => true,
          'db_host'           => 'localhost',
          'db_name'           => 'wordpressdb',
          'db_password'       => 'wpDBUpa55word',
          'db_user'           => 'wordpressdbuser',
          'docroot'           => '/var/www/wordpress/wordpress/',
          'port'              => '80',
          'serveraliases'     => "$::hostname",
          'vhost_name'        => "$::network_primary_ip",
          'wp_install_parent' => '/var/www/wordpress/',
          'wp_owner'          => 'wordpress',
          'wp_group'          => 'wordpress'
        }},
      'app_parent'     => '/opt/',
      'config_mode'    => 'dependent',
      'package_ensure' => 'present',
    } end
    describe 'when config_mode is \'dependent\'' do

      describe 'input validation tests' do
       context 'when wp_install_parent is present, and does not end with a trailing /' do
          it do
            params.merge!({'app_hash' => {
              'wordpressvhost' => {
                'wp_install_parent' =>  'foo',
                'create_group' => true,
                'create_user' => true,
              }
            }})
            expect { subject }.to raise_error(Puppet::Error, /does not match "\/\$"/)
          end
        end
        context 'when wp_install_parent is not present, and app_parent does not end with a trailing / ' do
          it do
            params.merge!({'app_hash' => {'wordpressvhost' => {
                'create_group' => true,
                'create_user' => true,}},
              'app_parent' => '/tmp'})
            expect { subject }.to raise_error(Puppet::Error, /does not match "\/\$"/)
          end
        end
        context 'When app_hash is not a hash' do
          it do
            params.merge!({'app_hash' => 'BOGON',})
            expect { subject }.to raise_error(Puppet::Error, /"BOGON" is not a Hash.  It looks to be a String/)
          end
        end
        context 'When config_mode is not \'apponly\' or \'dependent\'' do
          it do
            params.merge!({'config_mode' => 'BOGON',})
            expect { subject }.to raise_error(Puppet::Error, /The dependent class only supports the values of 'dependent' and 'apponly' for the config_mode parameter. BOGON is not a supported value/)
          end
        end
        context "When create_user is not a boolean" do
          it do
            params.merge!({'app_hash' => { 'wordpressvhost' => { 'create_user' => 'USER','create_group' => true,}} })
            expect { subject }.to raise_error(Puppet::Error, /"USER" is not a boolean.  It looks to be a String/)
          end
        end
        context "When create_group is not a boolean" do
          it do
            params.merge!({'app_hash' => { 'wordpressvhost' => { 'create_group' => 'GROUP','create_user' => false}} })
            expect { subject }.to raise_error(Puppet::Error, /"GROUP" is not a boolean.  It looks to be a String/)
          end
        end
      end
      describe 'module files'do
        [ 'wp_htaccess_configuration',
          'wp_installer',
          'wp_php_configuration',
          'wp_plugins',
          'wp_setup_files_dir',
          'wp_themes',
          'wp_wordpress_uploads',
          '/var/www/wordpress/',
          '/var/www/wordpress/wordpress/',
        ].each do |wp_files|
          it "should contain #{wp_files}" do
            params.merge!({'config_mode' => 'dependent'})
            should contain_file(wp_files)
          end
        end
      end
      describe 'dependent classes' do
        ['Mysql','Mysql::Server','Apache','Apache::Params'].each do |inclclass|
          it {should contain_class(inclclass)}
        end
      end
      describe 'Classes which are brought in via hiera when using mysql_factory' do
        pending 'this cannot be tested cleanly' do
          it do
            should contain_class('MySQL::Php')
          end
        end
      end
    end
  end
end
