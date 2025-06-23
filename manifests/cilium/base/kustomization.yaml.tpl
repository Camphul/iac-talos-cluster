helmCharts:
  - name: cilium
    repo: https://helm.cilium.io/
    version: ${cilium_version}
    releaseName: cilium
    namespace: kube-system
    includeCRDs: true
    valuesFile: values.yaml
