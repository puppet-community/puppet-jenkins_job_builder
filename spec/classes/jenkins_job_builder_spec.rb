# frozen_string_literal: true

require 'spec_helper'

describe 'jenkins_job_builder' do
  let(:pre_condition) { "service { 'jenkins': }" }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:expected_packages) do
        case os_facts[:os]['family']
        when 'Debian'
          %w[python python-pip python-yaml]
        when 'RedHat'
          case os_facts[:os]['release']['major']
          when '6'
            %w[python python-pip PyYAML python-argparse]
          when '7'
            %w[python python2-pip PyYAML]
          else
            []
          end
        else
          []
        end
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('jenkins_job_builder::params') }

      it { is_expected.to contain_class('jenkins_job_builder::install').that_comes_before('class[jenkins_job_builder::config]') }

      it { is_expected.to contain_class('jenkins_job_builder::config') }

      it { is_expected.to contain_package('jenkins-job-builder').with_ensure('latest') }

      it do
        expected_packages.map do |dep|
          is_expected.to contain_package(dep).with_ensure('present')
        end
      end

      it { is_expected.to contain_file('/etc/jenkins_jobs').with_ensure('directory') }
      it { is_expected.to contain_file('/etc/jenkins_jobs/jenkins_jobs.ini').with_ensure('file') }

      it do
        is_expected.to contain_ini_setting('jenkins-jobs user').with(
          'ensure'  => 'present',
          'path'    => '/etc/jenkins_jobs/jenkins_jobs.ini',
          'section' => 'jenkins',
          'setting' => 'user',
          'value'   => nil,
          'require' => 'File[/etc/jenkins_jobs/jenkins_jobs.ini]'
        )
      end

      it do
        is_expected.to contain_ini_setting('jenkins-jobs password').with(
          'ensure'  => 'present',
          'path'    => '/etc/jenkins_jobs/jenkins_jobs.ini',
          'section' => 'jenkins',
          'setting' => 'password',
          'value'   => nil,
          'require' => 'File[/etc/jenkins_jobs/jenkins_jobs.ini]'
        )
      end

      it do
        is_expected.to contain_ini_setting('jenkins-jobs url').with(
          'ensure'  => 'present',
          'path'    => '/etc/jenkins_jobs/jenkins_jobs.ini',
          'section' => 'jenkins',
          'setting' => 'url',
          'value'   => 'http://localhost:8080',
          'require' => 'File[/etc/jenkins_jobs/jenkins_jobs.ini]'
        )
      end

      it do
        is_expected.to contain_ini_setting('jenkins-jobs hipchat token').with(
          'ensure'  => 'present',
          'path'    => '/etc/jenkins_jobs/jenkins_jobs.ini',
          'section' => 'hipchat',
          'setting' => 'authtoken',
          'value'   => '',
          'require' => 'File[/etc/jenkins_jobs/jenkins_jobs.ini]'
        )
      end

      context 'install from git' do
        let :params do
          {
            install_from_git: true
          }
        end

        it do
          is_expected.to contain_vcsrepo('/opt/jenkins_job_builder').with(
            'ensure'   => 'latest',
            'provider' => 'git'
          )
        end
      end

      context 'install from pkg' do
        let :params do
          {
            install_from_pkg: true
          }
        end
        let(:pkg) { os_facts[:os]['family'] == 'RedHat' && os_facts[:os]['release']['major'] == '7' ? 'python-jenkins-job-builder' : 'jenkins-job-builder' }

        it { is_expected.to contain_package(pkg).with_ensure('latest') }
      end

      context 'explicit timeout value' do
        let :params do
          {
            timeout: 25
          }
        end

        it do
          is_expected.to contain_ini_setting('jenkins-jobs timeout').with(
            'ensure'  => 'present',
            'path'    => '/etc/jenkins_jobs/jenkins_jobs.ini',
            'section' => 'jenkins',
            'setting' => 'timeout',
            'value'   => 25,
            'require' => 'File[/etc/jenkins_jobs/jenkins_jobs.ini]'
          )
        end
      end

      describe 'jenkins_job_builder with a hash of jobs' do
        let :params do
          {
            jobs: {
              'test01' => {
                'config' => {
                  'name'        => 'test01',
                  'description' => 'the first jenkins job'
                }
              },
              'test02' => {
                'config' => {
                  'name'        => 'test02',
                  'description' => 'the second jenkins job'
                }
              }
            }
          }
        end

        it do
          is_expected.to contain_file('/tmp/jenkins-test01.yaml').with(
            'content' => ['job' => params[:jobs]['test01']['config']].to_yaml
          )
        end

        it do
          is_expected.to contain_file('/tmp/jenkins-test02.yaml').with(
            'content' => ['job' => params[:jobs]['test02']['config']].to_yaml
          )
        end
      end
    end
  end

  context 'unsupported operating system' do
    let :facts do
      {
        osfamily: 'Solaris',
        operatingsystem: 'Nexenta',
        operatingsystemrelease: 'should_not_be_used',
        os: {
          'family' => 'Solaris',
          'name' => 'Nexenta'
        }
      }
    end

    it { is_expected.to compile.and_raise_error(%r{Nexenta not supported}) }
  end
end
