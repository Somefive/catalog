parameter: {
	// +usage=Specify the image of kube-state-metrics
	image: *"bitnami/kube-state-metrics:2.4.2" | string
	// +usage=Specify the imagePullPolicy of the image
	imagePullPolicy: *"IfNotPresent" | "Never" | "Always"
	// +usage=Specify the number of CPU units
	cpu: *0.1 | number
	// +usage=Specifies the attributes of the memory resource required for the container.
	memory: *"250Mi" | string
}
