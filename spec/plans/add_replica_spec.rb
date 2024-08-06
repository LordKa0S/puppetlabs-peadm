require 'spec_helper'

describe 'peadm::add_replica' do
  include BoltSpec::Plans

  def allow_standard_non_returning_calls
    allow_apply
    allow_any_task
    allow_any_command
    allow_any_out_message
  end

  describe 'basic functionality' do
    let(:params) { { 'primary_host' => 'primary', 'replica_host' => 'replica' } }
    let(:cfg) { { 'params' => { 'primary_host' => 'primary' } } }
    let(:certdata) do
      {
        'certificate-exists' => true,
        'certname'           => 'primary',
        'extensions'         => { '1.3.6.1.4.1.34380.1.1.9813' => 'A' },
        'dns-alt-names'      => []
      }
    end
    let(:certstatus) do
      {
        'certificate-status' => 'valid',
        'reason'             => 'Expires - 2099-01-01 00:00:00 UTC'
      }
    end

    it 'runs successfully when the primary does not have alt-names' do
      allow_standard_non_returning_calls
      expect_task('peadm::get_peadm_config').always_return(cfg)
      expect_task('peadm::cert_data').always_return(certdata).be_called_times(4)
      expect_task('peadm::cert_valid_status').always_return(certstatus)
      expect_task('package').always_return({ 'status' => 'uninstalled' })
      expect_task('peadm::agent_install')
        .with_params({ 'server'        => 'primary',
                       'install_flags' => [
                         'main:dns_alt_names=replica',
                         '--puppet-service-ensure', 'stopped',
                         'main:certname=replica'
                       ] })
      expect_plan('peadm::util::copy_file').be_called_times(5)

      expect_out_verbose.with_params('Current config is...')
      expect_out_verbose.with_params('Updating classification to...')
      expect(run_plan('peadm::add_replica', params)).to be_ok
    end

    it 'runs successfully when the primary has alt-names' do
      allow_standard_non_returning_calls
      expect_task('peadm::get_peadm_config').always_return(cfg)
      expect_task('peadm::cert_data').always_return(certdata.merge({ 'dns-alt-names' => ['primary', 'alt'] })).be_called_times(4)
      expect_task('peadm::cert_valid_status').always_return(certstatus)
      expect_task('package').always_return({ 'status' => 'uninstalled' })
      expect_task('peadm::agent_install')
        .with_params({ 'server'        => 'primary',
                       'install_flags' => [
                         'main:dns_alt_names=replica,alt',
                         '--puppet-service-ensure', 'stopped',
                         'main:certname=replica'
                       ] })
      expect_plan('peadm::util::copy_file').be_called_times(5)

      expect_out_verbose.with_params('Current config is...')
      expect_out_verbose.with_params('Updating classification to...')
      expect(run_plan('peadm::add_replica', params)).to be_ok
    end

    it 'handles the replica_postgresql_host parameter correctly' do
      allow_standard_non_returning_calls
      params_with_postgresql = params.merge({ 'replica_postgresql_host' => 'replica_pg' })

      expect_task('peadm::get_peadm_config').always_return(cfg)
      expect_task('peadm::cert_data').always_return(certdata).be_called_times(4)
      expect_task('peadm::cert_valid_status').always_return(certstatus)
      expect_task('package').always_return({ 'status' => 'uninstalled' })

      expect_task('peadm::get_psql_version')
        .with_targets(['replica_pg'])
        .always_return({ 'version' => '11' })

      allow_apply

      expect_command('systemctl reload pe-postgresql.service')
        .with_targets(['replica_pg'])

      expect_task('peadm::agent_install')
        .with_params({ 'server'        => 'primary',
                       'install_flags' => [
                         'main:dns_alt_names=replica',
                         '--puppet-service-ensure', 'stopped',
                         'main:certname=replica'
                       ] })
      expect_plan('peadm::util::copy_file').be_called_times(5)

      expect_out_verbose.with_params('Current config is...')
      expect_out_verbose.with_params('Updating classification to...')
      expect(run_plan('peadm::add_replica', params_with_postgresql)).to be_ok
    end
  end
end