parameter: {
	// +usage=Specify the image of kube-state-metrics
	image: *"bitnami/kube-state-metrics:2.4.2" | string
	// +usage=Specify the imagePullPolicy of the image
	imagePullPolicy: *"IfNotPresent" | "Never" | "Always"
	// +usage=Specify the exposeType of the kube-state-metrics service
	exposeType: *"ClusterIP" | "NodePort" | "LoadBalancer" | "ExternalName"
}
