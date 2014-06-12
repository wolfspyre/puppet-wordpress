#!/usr/bin/env rspec
require 'spec_helper'
describe 'wordpress::app', :type => :define do
  let :title do
    'test_wp_app'
  end
  describe 'On a RedHat 6 OS' do
    let :facts do {
      :concat_basedir         => '/dne',
      :lsbmajdistrelease      => '6',
      :network_primary_ip     => '1.2.3.4',
      :operatingsystemrelease => '6.1',
      :osfamily               => 'RedHat',
    } end
    let (:params) do {
      'app_archive'       => 'wordpress-3.5.2.zip',
      'app_install_dir'   => 'wordpress',
      'config_mode'       => 'apponly',
      'create_group'      => true,
      'create_user'       => true,
      'create_vhost'      => true,
      'db_host'           => 'localhost',
      'db_name'           => 'wordpressdb',
      'db_password'       => 'wpDBUpa55word',
      'db_user'           => 'wordpressdbuser',
      'docroot'           => '/var/www/wordpress/wordpress/',
      'enable_scponly'    => true,
      'manage_scponly'    => true,
      'port'              => '80',
      'serveraliases'     => "$::hostname",
      'vhost_name'        => "$::network_primary_ip",
      'wp_install_parent' => '/var/www/wordpress/'
    } end
    #it {p subject.resources}
    describe 'When config_mode is dependent' do
      #The only functional difference between dependent and apponly is that in dependent mode
      #we create a database on the local system, via the puppetlabs-mysql module.
      #
      #We'll test everything else in apponly.
      context 'when $db_host is not \'localhost\' or \'127.0.0.1\'' do
        it 'should error' do
          params.merge!({'config_mode' => 'dependent', 'db_host' => 'BOGON'})
          expect { subject }.to raise_error(Puppet::Error, /In dependent mode, the wordpress module only supports the values \'localhost\', and \'127.0.0.1\'/)
        end
      end
    end
    describe 'When config_mode is apponly' do
      describe 'user and group tests' do
        context 'when create_user is true and wp_owner is set' do
          it 'should contain the specified user' do
            params.merge!({'create_user' => true, 'wp_owner' => 'wordpress' })
            should contain_user('wordpress')
          end
          context 'when enable_scponly is true' do
            it 'should contain the specified user with scponly as its shell' do
              params.merge!({'create_user' => true, 'wp_owner' => 'wordpress', 'enable_scponly' => true })
              should contain_user('wordpress').with({'shell' => '/usr/bin/scponly'})
            end
          end
          context 'when enable_scponly is false' do
           it 'should contain the specified user with /dev/null as its shell' do
              params.merge!({'create_user' => true, 'wp_owner' => 'wordpress', 'enable_scponly' => false })
              should contain_user('wordpress')
              should contain_user('wordpress').with({'shell' => '/dev/null'})
            end
          end
        end
        context 'when create_user is false' do
          it 'should not create the user, even if wp_owner is set.' do
            params.merge!({'create_user' => false, 'wp_owner' => 'wordpress' })
            should_not contain_user('wordpress')
          end
        end
        context 'when create_group is true' do
          it 'should create the group' do
            params.merge!({'create_group' => true, 'wp_group' => 'wordpress' })
            should contain_group('wordpress')
          end
        end
        context 'when create_group is false' do
          it 'should not create the group, even if wp_group is set' do
            params.merge!({'create_group' => false, 'wp_group' => 'wordpress' })
            should_not contain_group('wordpress')
          end
        end
      end
      describe 'Module files' do
        ['test_wp_app_setup_files_dir','test_wp_app_themes','test_wp_app_plugins','test_wp_app_installer','test_wp_app_htaccess_configuration','test_wp_app_php_configuration','test_wp_app_wordpress_uploads'].each do |modulefiles|
          context "it should contain the #{modulefiles} file" do
            it do
              should contain_file(modulefiles)
            end
          end
        end
        context 'if create_vhost is false' do
          it 'should contain the file resource for the parent directory' do
            params.merge!({'create_vhost' => false,})
            should contain_file('/var/www/wordpress/').with('ensure' => 'directory')
          end
        end
        context 'if $wp_install_parent does not match $docroot' do
          it 'should contain the file resource for the parent directory' do
            should contain_file('/var/www/wordpress/').with('ensure' => 'directory')
          end
        end
      end
      describe 'Module execs' do
        ['test_wp_app_extract_installer','test_wp_app_extract_themes','test_wp_app_extract_plugins'].each do |modexecs|
          context "it should contain the #{modexecs} exec" do
            it do
              should contain_exec(modexecs)
            end
          end
        end
      end
    end
    describe 'when create_vhost is true' do
      it 'should create the vhost with $title_vhost as the vhost resource name' do
        should contain_apache__vhost('test_wp_app_vhost')
      end
      it {should contain_class('apache')}
      context 'When $vhost_server_name is set' do
        it 'should create the vhost with the value of the \'vhost_server_name\' parameter for its namevar' do
          params.merge!({'vhost_server_name' => 'wordpress.mysite.com' })
          should contain_apache__vhost('wordpress.mysite.com')
        end
        it {should contain_class('apache')}
      end
    end
    describe 'when create_vhost is false' do
      it 'should not contain the vhost' do
        params.merge!({'create_vhost' => false})
        should_not contain_apache__vhost('test_wp_app_vhost')
      end
      it 'should contain the file resource for the parent directory' do
        should contain_file('/var/www/wordpress/').with('ensure' => 'directory')
      end
    end
    describe 'when the app_install_dir is not \'wordpress\'' do
      context 'and create_vhost is true' do
        context 'and $docroot matches "${wp_install_parent}${app_install_dir}"' do
          it 'should move the extracted files to their parent directory, and remove the \'wordpress\' folder' do
            params.merge!({'create_vhost' => true, 'docroot' => '/tmp/wordypress/', 'wp_install_parent' => '/tmp/', 'app_install_dir' => 'wordypress' })
            should contain_exec('test_wp_app_move_wordpress_install').with('command' => '/bin/mv /tmp/wordpress/* /tmp/wordypress/&&/bin/rm -rf /tmp/wordpress')
          end
        end
        context 'but $docroot does not match "${wp_install_parent}${app_install_dir}"' do
          it 'should relocate the extracted wordpress install to the desired path' do
            params.merge!({'create_vhost' => true, 'docroot' => '/tmp/someplace/', 'wp_install_parent' => '/tmp/', 'app_install_dir' => 'wordypress' })
            should contain_exec('test_wp_app_move_wordpress_install').with('command' => '/bin/mv /tmp/wordpress /tmp/wordypress')
          end
        end
      end
      context 'and create_vhost is false' do
        it 'should relocate the extracted wordpress install to the desired path' do
          params.merge!({'create_vhost' => false, 'docroot' => '/tmp/wordypress/', 'wp_install_parent' => '/tmp/', 'app_install_dir' => 'wordypress' })
          should contain_exec('test_wp_app_move_wordpress_install').with('command' => '/bin/mv /tmp/wordpress /tmp/wordypress')
        end
      end
    end
    describe 'input validation' do
      ['docroot','wp_install_parent'].each do |parentdirs|
        context "when #{parentdirs} does not end with a trailing /" do
          it do
            params.merge!({parentdirs => '/tmp'})
            expect { subject }.to raise_error(Puppet::Error, /does not match "\/\$"/)
          end
        end
      end
      ['create_group','create_user','create_vhost','enable_scponly' ].each do |booltest|
        context "when #{booltest} is not a boolean" do
          it 'should error' do
            params.merge!({booltest => 'BOGON'})
            expect { subject }.to raise_error(Puppet::Error, /"BOGON" is not a boolean.  It looks to be a String/)
          end
        end
      end
    end
  end
end
