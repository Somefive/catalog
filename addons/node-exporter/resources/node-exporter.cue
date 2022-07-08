output: {
    type: "daemon"
    properties: {
        image: parameter["image"]
        imagePullPolicy: parameter["imagePullPolicy"]
        volumeMounts: {
            hostPath: [{
                name: "sys"
                mountPath: "/host/sys"
                mountPropagation: "HostToContainer"
                path: "/sys"
                readOnly: true
            }, {
                name: "root"
                mountPath: "/host/root"
                mountPropagation: "HostToContainer"
                path: "/"
                readOnly: true
            }]
        }
    }
    traits: [{
        type: "command"
        properties: args: [
            "--path.sysfs=/host/sys",
            "--path.rootfs=/host/root",
            "--no-collector.wifi",
            "--no-collector.hwmon", 
            "--collector.filesystem.ignored-mount-points=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/pods/.+)($|/)",
            "--collector.netclass.ignored-devices=^(veth.*)$",
        ]
    }, {
        type: "prometheus-scrape"
        properties: port: 9100
    }, {
        type: "resource"
        properties: {
            cpu: parameter["cpu"]
            memory: parameter["memory"]
        }
    }]
}