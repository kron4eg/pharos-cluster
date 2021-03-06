require "pharos/phases/configure_secrets_encryption"

describe Pharos::Phases::ConfigureSecretsEncryption do
  let(:master) { Pharos::Configuration::Host.new(address: 'test', private_address: 'private', role: 'master') }
  let(:config_hosts_count) { 1 }

  let(:config) { Pharos::Config.new(
      hosts: (1..config_hosts_count).map { |i| Pharos::Configuration::Host.new(role: 'worker') },
      network: {
        service_cidr: '1.2.3.4/16',
        pod_network_cidr: '10.0.0.0/16'
      },
      addons: {},
      etcd: {}
  ) }

  let(:ssh) { instance_double(Pharos::SSH::Client) }
  subject { described_class.new(master, config: config, ssh: ssh) }

    describe '#read_config_keys' do
      let(:file) { instance_double(Pharos::SSH::RemoteFile) }

      before do
        allow(ssh).to receive(:file).with('/etc/pharos/secrets-encryption/config.yml').and_return(file)
      end

      it 'returns nil if no config file existing' do
        expect(file).to receive(:exist?).and_return(false)

        expect(subject.read_config_keys).to be_nil
      end

      it 'returns aescbc keys if configured' do
        expect(file).to receive(:exist?).and_return(true)
        expect(file).to receive(:read).and_return(fixture("secrets_cfg.yaml"))

        expect(subject.read_config_keys).to eq({
          'key1' => 's6Xm3BlhHWkD0/5mW5tcks5kcdeWxE3qWkx/gA6hlcI=',
          'key2' => '23VanHzmFuMQgfnVQrp9oJf0lLa82mThTBVDXd8Uw0s=',
        })
      end
    end
  end
