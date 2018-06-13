# frozen_string_literal: true

module Pharos
  module Host
    class El7 < Configurer
      DOCKER_VERSION = '1.13.1'
      CONTAINERD_VERSION = '1.1.0'
      CFSSL_VERSION = '1.2'

      # @param path [Array]
      # @return [String]
      def script_path(*path)
        File.join(__dir__, 'scripts', *path)
      end

      def install_essentials
        exec_script(
          'configure-essentials.sh',
          HTTP_PROXY: host.http_proxy.to_s,
          SET_HTTP_PROXY: host.http_proxy.nil? ? 'false' : 'true'
        )
      end

      def configure_repos
        exec_script('repos/pharos_centos7.sh')
      end

      def configure_netfilter
        exec_script('configure-netfilter.sh')
      end

      def configure_cfssl
        exec_script(
          'configure-cfssl.sh',
          ARCH: host.cpu_arch.name
        )
      end

      def configure_container_runtime
        if docker?
          exec_script(
            'configure-docker.sh',
            DOCKER_VERSION: DOCKER_VERSION
          )
        elsif containerd?
          exec_script(
            'configure-containerd.sh',
            CONTAINERD_VERSION: CONTAINERD_VERSION,
            CRIO_STREAM_ADDRESS: host.peer_address,
            CPU_ARCH: host.cpu_arch.name,
            IMAGE_REPO: cluster_config.image_repository
          )
        else
          raise Pharos::Error, "Unknown container runtime: #{host.container_runtime}"
        end
      end

      def ensure_kubelet(args)
        exec_script(
          'ensure-kubelet.sh',
          args
        )
      end

      def install_kube_packages(args)
        exec_script(
          'install-kube-packages.sh',
          args
        )
      end

      def upgrade_kubeadm(version)
        exec_script(
          "upgrade-kubeadm.sh",
          VERSION: version,
          ARCH: host.cpu_arch.name
        )
      end
    end
  end
end
