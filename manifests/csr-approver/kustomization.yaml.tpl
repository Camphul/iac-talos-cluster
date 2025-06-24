helmCharts:
  - name: kubelet-csr-approver
    repo: https://postfinance.github.io/kubelet-csr-approver
    version: 1.2.10
    releaseName: kubelet-csr-approver
    namespace: kube-system
    includeCRDs: false
    valuesFile: values.yaml
