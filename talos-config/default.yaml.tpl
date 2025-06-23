machine:
  nodeLabels:
    topology.kubernetes.io/region: ${topology_region}
    cilium/bgp-peering-policy: default

  kubelet:
    defaultRuntimeSeccompProfileEnabled: true
    extraConfig:
      serverTLSBootstrap: true
      featureGates:
        UserNamespacesSupport: true
        UserNamespacesPodSecurityStandards: true
    extraArgs:
      # https://github.com/siderolabs/talos-cloud-controller-manager#node-certificate-approval
      cloud-provider: external
      rotate-server-certificates: true

  network:
    nameservers:
      - ${network_gateway}
  registries:
    mirrors:
      ghcr.io:
        endpoints:
          - http://rpi01.home.lsapps.nl:5004
      docker.io:
        endpoints:
          - http://rpi01.home.lsapps.nl:5000
      gcr.io:
        endpoints:
          - http://rpi01.home.lsapps.nl:5003
      registry.k8s.io:
        endpoints:
          - http://rpi01.home.lsapps.nl:5001
      quay.io:
        endpoints:
          - http://rpi01.home.lsapps.nl:5002
    config:
      rpi01.home.lsapps.nl:
        tls:
          insecureSkipVerify: true

  time:
    servers:
      - ${network_gateway}
      - 0.nl.pool.ntp.org
      - 1.nl.pool.ntp.org
      - 2.nl.pool.ntp.org
      - 3.nl.pool.ntp.org

  install:
    disk: ${install_disk_device}
    image: ${install_image_url}
    bootloader: true
    wipe: false

  systemDiskEncryption:
    ephemeral:
      provider: luks2
      keys:
        - nodeID: { }
          slot: 0
    state:
      provider: luks2
      keys:
        - nodeID: { }
          slot: 0

  kernel:
    modules:
      - name: br_netfilter
        parameters:
          - nf_conntrack_max=131072

  sysctls:
    net.bridge.bridge-nf-call-ip6tables: "1"
    net.bridge.bridge-nf-call-iptables: "1"
    net.ipv4.ip_forward: "1"
    user.max_user_namespaces: "11255"

  files:
    - path: /var/cri/conf.d/metrics.toml
      op: create
      content: |
        [metrics]
        address = "0.0.0.0:11234"

  features:
    kubePrism:
      enabled: true
      port: 7445
    hostDNS:
      enabled: false
      forwardKubeDNSToHost: false

# https://www.talos.dev/v1.5/kubernetes-guides/network/deploying-cilium/
cluster:
  network:
    cni:
      name: none
  proxy:
    disabled: true
