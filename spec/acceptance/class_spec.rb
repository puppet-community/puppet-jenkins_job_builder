# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'jenkins_job_builder class' do
  context 'with a defined job' do
    it 'works with no errors' do
      pp = <<-EOS
      class { 'jenkins': } ->
      class { 'jenkins_job_builder': }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true, debug: true, trace: true)
      apply_manifest(pp, catch_changes: true, debug: true, trace: true)
    end

    describe package('jenkins-job-builder') do
      it { is_expected.to be_installed.by('pip') }
    end

    # TODO: test ini file

    yaml_content = <<~'YAML'
      ---
        - job:
             description: "This a test job"
             name: "test"
             project-type: "freestyle"
             scm:
              - git:
                 branches:
                   - "*/master"
                 builders:
                  - shell: "#!/bin/bash -l\necho \"test\"\n"
                 triggers:
                  - pollscm: "*/1 * * * *"
                 url: "git@github.com:opentable/puppet-jenkins_job_builder"
    YAML

    describe file('/tmp/jenkins-test.yaml') do
      it { is_expected.to be_file }
      its(:content) { is_expected.to == yaml_content }
    end
  end
end
