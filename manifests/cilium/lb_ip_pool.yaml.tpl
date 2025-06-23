apiVersion: cilium.io/v2alpha1
kind: CiliumLoadBalancerIPPool
metadata:
  name: ip-pool
spec:
  blocks:
    - start: 10.10.80.90
      stop: 10.10.80.120
