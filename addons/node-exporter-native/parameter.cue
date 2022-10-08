parameter: {

    // global parameters

    // +usage=The namespace of the node-exporter to be installed
    namespace: *"o11y-system" | string
    // +usage=The name of the addon application
    name: *"addon-node-exporter" | string
    // +usage=The clusters to install
    clusters?: [...string]


    // node-exporter parameters

    // +usage=Specify the image of node-exporter
	image: *"prom/node-exporter" | string
	// +usage=Specify the imagePullPolicy of the image
	imagePullPolicy: *"IfNotPresent" | "Never" | "Always"
	// +usage=Specify the number of CPU units
	cpu: *0.2 | number
	// +usage=Specifies the attributes of the memory resource required for the container.
	memory: *"250Mi" | string

}