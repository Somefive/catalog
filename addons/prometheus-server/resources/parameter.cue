parameter: {
	// +usage=Specify the image of prometheus-server
	image: *"quay.io/prometheus/prometheus:v2.34.0" | string
	// +usage=Specify the imagePullPolicy of the image
	imagePullPolicy: *"IfNotPresent" | "Never" | "Always"
	// +usage=Specify the number of CPU units
	cpu: *0.5 | number
	// +usage=Specifies the attributes of the memory resource required for the container.
	memory: *"1024Mi" | string
	// +usage=Specify the service type for expose prometheus server. If empty, it will be not exposed.
	serviceType: *"LoadBalancer" | "ClusterIP" | "NodePort" | ""
	// +usage=If prometheus server already exists, set the external name for the prometheus server.
	externalName: *"" | string
	// +usage=If specified, the prometheus server will mount the config map as the additional config.
	customConfig: *"" | string
	// +usage=If specified, thanos sidecar will be attached and ports will be exposed
	thanosSidecar: *false | bool
}
