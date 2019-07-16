import pulumi
from pulumi_kubernetes.apps.v1 import Deployment
from pulumi_kubernetes.core.v1 import ServiceAccount, ConfigMap, Service
from pulumi_kubernetes.rbac.v1beta1 import ClusterRole, ClusterRoleBinding

def create():
    app_labels = { "app": "nginx" }

    serviceAccount = ServiceAccount("coredns", metadata = { "name" : "coredns", "namespace" : "kube-system" })
    
    clusterRole = ClusterRole("system:coredns", 
        metadata = { "name": "system:coredns", "labels": { "kubernetes.io/bootstrapping" : "rbac-defaults" }},
        rules = [{"apiGroups" : [""], "resources" : [ "endpoints", "services", "pods", "namespaces" ], "verbs" : [ "list", "watch" ] }])
    
    clusterRoleBinding = ClusterRoleBinding("system:coredns",
        metadata = { "name": "system:coredns", 
                     "labels": { "kubernetes.io/bootstrapping" : "rbac-defaults" }, 
                     "annotations": { "rbac.authorization.kubernetes.io/autoupdate" : "true" } },
        role_ref = { "apiGroup" : "rbac.authorization.k8s.io",
                     "kind" : "ClusterRole",
                     "name" : "system:coredns"},
        subjects = [ {"kind": "ServiceAccount", "name" : "coredns", "namespace" : "kube-system"} ])

    configMap = ConfigMap("coredns",
        metadata = { "name" : "coredns", "namespace" : "kube-system" },
        data = { "Corefile" :
        """.:53 {
            errors
            health
            kubernetes cluster.local in-addr.arpa ip6.arpa {
                pods insecure
                upstream
                fallthrough in-addr.arpa ip6.arpa
            }
            prometheus :9153
            proxy . /etc/resolv.conf
            cache 30
            loop
            reload
            loadbalance
        }"""
        })
    
    deployment = Deployment("coredns",
        metadata = { "name": "coredns",
                     "namespace" : "kube-system",
                     "labels": { "k8s-app" : "kube-dns", "kubernetes.io/name" : "CoreDNS" }},
        spec = { "selector": { "matchLabels": {"k8s-app" : "kube-dns"} },
                 "replicas": 2,
                 "strategy": { "type": "RollingUpdate", "rollingUpdate" : { "maxUnavailable" : 1 } },
                 "template": {
                    "metadata": { "labels": {"k8s-app" : "kube-dns"} },
                    "spec": { 
                        "serviceAccountName" : "coredns",
                        "tolerations" : [
                            { "key" : "node-role.kubernetes.io/master", "effect" : "NoSchedule" },
                            { "key" : "CriticalAddonsOnly", "operator" : "Exists" },
                        ],
                        "volumes": [{ "name" : "config-volume",
                                      "configMap" : { "name": "coredns", "items" : [{ "key": "Corefile", "path": "Corefile" }] }
                                   }],
                        "dnsPolicy": "Default",
                        "containers": [{ "name": "coredns", 
                                         "image": "coredns/coredns:1.2.2",
                                         "imagePullPolicy": "IfNotPresent", 
                                         "resources": { "limits" : { "memory" : "170Mi" },
                                                         "requests" : { "cpu" : "100m", "memory" : "70Mi" } },
                                         "args":  [ "-conf", "/etc/coredns/Corefile" ],
                                         "volumeMounts": [ { "name" : "config-volume" , "mountPath" : "/etc/coredns", "readOnly" : True } ],
                                         "ports": [ { "containerPort" : 53, "name" : "dns", "protocol" : "UDP" },
                                                    { "containerPort" : 53, "name" : "dns-tcp", "protocol" : "TCP" },
                                                    { "containerPort" : 9153, "name" : "metrics", "protocol" : "TCP" } ],
                                         "securityContext": { "allowPrivilegeEscalation" : False, 
                                                              "capabilities" : { "add" : [ "NET_BIND_SERVICE" ], "drop" : [ "all" ] } },
                                         "livenessProbe": { "httpGet": { "path" : "/health", "port" : 8080, "scheme" : "HTTP" },
                                                            "initialDelaySeconds": 60,
                                                            "timeoutSeconds": 5,
                                                            "successThreshold": 1,
                                                            "failureThreshold": 5 }
                                        }]}
                    }   
                }
        )

    service = Service("kube-dns",
                      metadata = { "name": "kube-dns",
                                   "namespace" : "kube-system",
                                   "labels": { "k8s-app" : "kube-dns", "kubernetes.io/name" : "CoreDNS", "kubernetes.io/cluster-service" : "true" },
                                   "annotations": { "prometheus.io/port" : "9153", "prometheus.io/scrape" : "true" } },
                      spec = {  "selector": {"k8s-app" : "kube-dns"},
                                "clusterIP": "10.32.0.10",
                                "ports": [ { "port" : 53, "name" : "dns", "protocol" : "UDP" },
                                           { "port" : 53, "name" : "dns-tcp", "protocol" : "TCP" } ] }
                     )
    
#pulumi.export("name", deployment.metadata["name"])