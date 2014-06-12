#!/usr/bin/env rspec
require 'spec_helper'

describe 'wordpress::scponly', :type => :class do
  context 'input validation' do

#    ['path'].each do |paths|
#      context "when the #{paths} parameter is not an absolute path" do
#        let (:params) {{ paths => 'foo' }}
#        it 'should fail' do
#          expect { subject }.to raise_error(Puppet::Error, /"foo" is not an absolute path/)
#        end
#      end
#    end#absolute path

#    ['array'].each do |arrays|
#      context "when the #{arrays} parameter is not an array" do
#        let (:params) {{ arrays => 'this is a string'}}
#        it 'should fail' do
#           expect { subject }.to raise_error(Puppet::Error, /is not an Array./)
#        end
#      end
#    end#arrays


#    ['enable_scponly'].each do |bools|
#      context "when the #{bools} parameter is not an boolean" do
#        let (:params) {{bools => "BOGON"}}
#        it 'should fail' do
#          expect { subject }.to raise_error(Puppet::Error, /"BOGON" is not a boolean.  It looks to be a String/)
#        end
#      end
#    end#bools

#    ['hash'].each do |hashes|
#      context "when the #{hashes} parameter is not an hash" do
#        let (:params) {{ hashes => 'this is a string'}}
#        it 'should fail' do
#           expect { subject }.to raise_error(Puppet::Error, /is not a Hash./)
#        end
#      end
#    end#hashes

#    ['ensure',].each do |strings|
#      context "when the #{strings} parameter is not a string" do
#        let (:params) {{strings => false }}
#        it 'should fail' do
#          expect { subject }.to raise_error(Puppet::Error, /false is not a string./)
#        end
#      end
#    end#strings
     context 'when ensure has an invalid value' do
      let (:params) {{'ensure' => 'BOGON'}}
      it 'should fail' do
        expect { subject }.to raise_error(Puppet::Error, /does not match/)
      end
    end

  end#input validation
  ['Debian','RedHat'].each do |osfam|
    context "When on an #{osfam} system" do
      let (:facts) {{'osfamily' => osfam}}
      context 'when wordpress::enable_scponly is true' do
        let (:params) {{'enable_scponly' => true, 'ensure' => 'latest'}}
        ['present','latest'].each do |ensureval|
          context "when the package_ensure param has the value of '#{ensureval}'" do
            let (:params) {{'enable_scponly' => true, 'ensure' => ensureval }}
            it do
              should contain_package('scponly').with({'ensure' => ensureval})
            end
          end
        end
      end

      context 'when wordpress::enable_scponly is false' do
        let (:params) {{'enable_scponly' => false, 'ensure' => 'latest'}}
        it 'should fail. This class should not be included. we should not do anything' do
          expect {subject}.to raise_error(Puppet::Error, /must be true to manage scponly/)
        end
      end
    end
  end
end
