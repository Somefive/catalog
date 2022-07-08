parameter: {
    repoUrl: *"https://charts.kubevela.net/addons" | string
    chart: *"kube-state-metrics" | string
    chartVersion: *"3.4.1" | string
    targetNamespace: *"o11n-system" | string
    imageRepository: *"oamdev/kube-state-metrics" | string
    imageTag: *"v2.1.0" | string
}
