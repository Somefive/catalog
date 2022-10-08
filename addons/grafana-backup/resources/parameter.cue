parameter: {
	// +usage=Specify the image of kube-state-metrics
	image: *"grafana/grafana:8.5.3" | string
	// +usage=Specify the imagePullPolicy of the image
	imagePullPolicy: *"IfNotPresent" | "Never" | "Always"
	// +usage=Specify the number of CPU units
	cpu: *0.5 | number
	// +usage=Specifies the attributes of the memory resource required for the container.
	memory: *"1024Mi" | string
	// +usage=Specify the service type for expose prometheus server. Default to be ClusterIP.
	serviceType: *"ClusterIP" | "NodePort" | "LoadBalancer"
	// +usage=Specify the admin user for grafana
	adminUser: *"admin" | string
	// +usage=Specify the admin password for grafana
	adminPassword: *"kubevela" | string
}
