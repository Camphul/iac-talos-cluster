machine:
  nodeLabels:
    topology.kubernetes.io/zone: ${topology_zone}
  certSANs:
    - ${hostname}
    - ${ipv4_local}

  network:
    hostname: ${hostname}
    interfaces:
      - interface: ${network_interface}
        dhcp: false
        addresses:
          - ${ipv4_local}/${network_ip_prefix}
        routes:
          - network: 0.0.0.0/0
            gateway: ${network_gateway}
    nameservers:
%{ for nameserver in nameservers ~}
      - ${nameserver}
%{endfor }
    searchDomains:
%{ for seach_domain in search_domains ~}
        - ${seach_domain}
%{ endfor ~}
    extraHostEntries:
      - ip: ${ipv4_vip}
        aliases:
          - ${cluster_domain}
      - ip: 10.10.10.170 # RPI hosting registry mirrors
        # The host alias.
        aliases:
          - rpi01.home.lsapps.nl
