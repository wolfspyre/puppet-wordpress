#!/usr/bin/env rspec
require 'spec_helper'
describe 'wordpress', :type => :class do
  describe 'On a RedHat OS' do
    let :facts do {
      :concat_basedir         => '/dne',
      :lsbmajdistrelease      => '5',
      :network_primary_ip     => '1.2.3.4',
      :operatingsystemrelease => '5.9',
      :osfamily               => 'RedHat',
    } end
    let (:params) do {
      'app_archive'        => 'wordpress-3.4.1.zip',
      'app_dir'            => 'wordpress',
      'app_hash'           => {
        'wordpressvhost' => {
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
      'app_parent'         => '/opt',
      'config_mode'        => 'standalone',
      'enable_scponly'     => true,
      'manage_scponly_pkg' => true,
      'mysql_version'      => '5.5',
      'package_ensure'     => 'present',
    } end
    describe 'input validation tests' do
      context 'when package_ensure is not \'latest\' or \'supported\'' do
        it do
          params.merge!({'package_ensure' => 'BOGON'})
          expect { subject }.to raise_error(Puppet::Error, /"BOGON" does not match/)
        end
      end
      context 'when config_mode is not \'dependent\', \'standalone\', or \'apponly\'' do
        it do
          params.merge!({'config_mode' => 'BOGON'})
          expect { subject }.to raise_error(Puppet::Error, /unsupported config_mode/)
        end
      end

      ['enable_scponly', 'manage_scponly_pkg'].each do |bools|
        context "when #{bools} is not a boolean" do
          it do
            params.merge!({bools => 'BOGON'})
            expect { subject }.to raise_error(Puppet::Error, /is not a boolean/)
          end
        end
      end
    end
    describe 'mode testing' do
      ['apponly', 'dependent'].each do |wpmode|
        context "when config_mode is \'#{wpmode}\'"do
          it do
            params.merge!({'config_mode' => wpmode})
            should contain_class('wordpress::dependent')
          end
        end
      end
      context 'When config_mode is \'standalone\'' do
        it 'should contain the standalone class' do
          params.merge!({'config_mode' => 'standalone'})
          should contain_class('wordpress::standalone')
        end
      end
    end

    describe 'scponly logic:' do
      context 'when enable_scponly is true' do
        context 'and manage_scponly_pkg is true' do
          it do
            should contain_class('wordpress::scponly')
          end
        end
        context 'when manage_scponly_pkg is false' do
          it do
            params.merge!({'manage_scponly_pkg' => false})
            should_not contain_class('wordpress::scponly')
          end
        end
      end
      context 'when enable_scponly is false' do
        it do
          params.merge!({'enable_scponly' => false, 'manage_scponly_pkg' => false})
          should_not contain_class('wordpress::scponly')
        end
      end

    end
  end
end
