parameter: {
	// +usage=Specify the image of prometheus-server
	image: *"quay.io/prometheus/prometheus:v2.34.0" | string
	// +usage=Specify the imagePullPolicy of the image
	imagePullPolicy: *"IfNotPresent" | "Never" | "Always"
	// +usage=Specify the number of CPU units
	cpu: *0.1 | number
	// +usage=Specifies the attributes of the memory resource required for the container.
	memory: *"250Mi" | string
	// +usage=Specify the service type for expose prometheus server. If empty, it will be not exposed.
	serviceType: *"LoadBalancer" | "ClusterIP" | "NodePort" | ""
	// +usage=If prometheus server already exists, set the external name for the prometheus server.
	externalName: *"" | string
}
