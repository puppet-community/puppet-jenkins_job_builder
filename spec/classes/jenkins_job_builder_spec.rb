require 'spec_helper'

describe 'jenkins_job_builder' do
  context 'supported operating systems' do
    ['Debian', 'RedHat'].each do |osfamily|
      describe "jenkins_job_builder class without any parameters on #{osfamily}" do
        let(:params) {{ }}
        let(:facts) {{
          :osfamily => osfamily,
        }}

        it { should compile.with_all_deps }

        it { should contain_class('jenkins_job_builder::params') }

        it { should contain_class('jenkins_job_builder::install').that_comes_before('jenkins_job_builder::config') }
        it { should contain_class('jenkins_job_builder::config') }

        it { should contain_package('jenkins-job-builder').with_ensure('latest') }

        it { should contain_file('/etc/jenkins_jobs').with_ensure('directory') }
        it { should contain_file('/etc/jenkins_jobs/jenkins_jobs.ini').with_ensure('present')}

        it { should contain_ini_setting('jenkins-jobs user').with(
          'ensure'  => 'present',
          'path'    => '/etc/jenkins_jobs/jenkins_jobs.ini',
          'section' => 'jenkins',
          'setting' => 'user',
          'value'   => '',
          'require' => 'File[/etc/jenkins_jobs/jenkins_jobs.ini]'
        )}

        it { should contain_ini_setting('jenkins-jobs password').with(
          'ensure'  => 'present',
          'path'    => '/etc/jenkins_jobs/jenkins_jobs.ini',
          'section' => 'jenkins',
          'setting' => 'password',
          'value'   => '',
          'require' => 'File[/etc/jenkins_jobs/jenkins_jobs.ini]'
        )}

        it { should contain_ini_setting('jenkins-jobs url').with(
          'ensure'  => 'present',
          'path'    => '/etc/jenkins_jobs/jenkins_jobs.ini',
          'section' => 'jenkins',
          'setting' => 'url',
          'value'   => 'http://localhost:8080',
          'require' => 'File[/etc/jenkins_jobs/jenkins_jobs.ini]'
        )}

        it { should contain_ini_setting('jenkins-jobs hipchat token').with(
          'ensure'  => 'present',
          'path'    => '/etc/jenkins_jobs/jenkins_jobs.ini',
          'section' => 'hipchat',
          'setting' => 'authtoken',
          'value'   => '',
          'require' => 'File[/etc/jenkins_jobs/jenkins_jobs.ini]'
        )}
      end
    end
    describe "jenkins_job_builder class without any parameters on a 'Debian' OS" do
      let(:params) {{ }}
      let(:facts) {{
        :osfamily => 'Debian',
      }}

      ['python', 'python-pip', 'pyyaml'].each do |dep|
        it { should contain_package(dep).with_ensure('present') }
      end

    end
    describe "jenkins_job_builder class without any parameters on a 'RedHat' OS" do
      let(:params) {{ }}
      let(:facts) {{
        :osfamily => 'RedHat',
      }}

      ['python', 'python-pip', 'pyyaml', 'python-argparse'].each do |dep|
        it { should contain_package(dep).with_ensure('present') }
      end

    end
    describe "jenkins_job_builder class without any parameters on a 'RedHat/CentOS' 7.x" do
      let(:params) {{ }}
      let(:facts) {{
        :osfamily => 'RedHat',
        :operatingsystemmajrelease => '7'
      }}

      ['python', 'python-pip', 'python-devel', 'pyyaml'].each do |dep|
        it { should contain_package(dep).with_ensure('present') }
      end
      it { should_not contain_package('python-argparse') }

    end
  end

  context 'install from git' do
    describe 'jenkins_job_builder installed from git' do
      let(:params) {{
        :install_from_git => true
      }}
      let(:facts) {{
        :osfamily => 'Debian'
      }}

      it { should contain_vcsrepo('/opt/jenkins_job_builder').with(
        'ensure'   => 'latest',
        'provider' => 'git'
      )}

    end
  end

  context 'unsupported operating system' do
    describe 'jenkins_job_builder class without any parameters on Solaris/Nexenta' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta'
      }}

      it { expect { should contain_package('jenkins_job_builder') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end

  context 'creates jobs' do
    describe 'jenkins_job_builder with a hash of jobs' do
      let(:params) {{
        :jobs => {
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
      }}
      let(:facts) {{
        :osfamily => 'Debian'
      }}

      it { should contain_file('/tmp/jenkins-test01.yaml').with_content(
        "--- \n  - job: \n      name: test01\n      description: \"the first jenkins job\"\n"
      )}

      it { should contain_file('/tmp/jenkins-test02.yaml').with_content(
        "--- \n  - job: \n      name: test02\n      description: \"the second jenkins job\"\n"
      )}
    end
  end

end
