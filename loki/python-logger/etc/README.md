## Build the docker image

cd .. (dir above etc folder)

    docker buildx build --platform linux/arm64 -t mrangelcruz1960/python-logger:latest .
    docker push mrangelcruz1960/python-logger:latest


This will be pushed to DockerHub.

## Deployment manifest

    k get deploy python-logger -o yaml -n monitoring

    apiVersion: apps/v1
    kind: Deployment
    metadata:
    annotations:
        deployment.kubernetes.io/revision: "3"
        kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"app":"python-logger"},"name":"python-logger","namespace":"monitoring"},"spec":{"replicas":1,"selector":{"matchLabels":{"app":"python-logger"}},"template":{"metadata":{"labels":{"app":"python-logger","job":"python-logger"}},"spec":{"containers":[{"image":"mrangelcruz1960/python-logger:latest","imagePullPolicy":"Always","name":"python-logger"}]}}}}
    creationTimestamp: "2025-10-11T00:29:25Z"
    generation: 3
    labels:
        app: python-logger
    name: python-logger
    namespace: monitoring
    resourceVersion: "96695"
    uid: a30c78ad-1e4e-4003-b0a1-3fde9d868e45
    spec:
    progressDeadlineSeconds: 600
    replicas: 1
    revisionHistoryLimit: 10
    selector:
        matchLabels:
        app: python-logger
    strategy:
        rollingUpdate:
        maxSurge: 25%
        maxUnavailable: 25%
        type: RollingUpdate
    template:
        metadata:
        annotations:
            kubectl.kubernetes.io/restartedAt: "2025-10-10T21:43:59-05:00"
        creationTimestamp: null
        labels:
            app: python-logger
            job: python-logger
        spec:
        containers:
        - image: mrangelcruz1960/python-logger:latest
            imagePullPolicy: Always
            name: python-logger
            resources: {}
            terminationMessagePath: /dev/termination-log
            terminationMessagePolicy: File
        dnsPolicy: ClusterFirst
        restartPolicy: Always
        schedulerName: default-scheduler
        securityContext: {}
        terminationGracePeriodSeconds: 30
    status:
    availableReplicas: 1
    conditions:
    - lastTransitionTime: "2025-10-11T02:43:26Z"
        lastUpdateTime: "2025-10-11T02:43:26Z"
        message: Deployment has minimum availability.
        reason: MinimumReplicasAvailable
        status: "True"
        type: Available
    - lastTransitionTime: "2025-10-11T00:29:25Z"
        lastUpdateTime: "2025-10-11T02:44:02Z"
        message: ReplicaSet "python-logger-84774f7c94" has successfully progressed.
        reason: NewReplicaSetAvailable
        status: "True"
        type: Progressing
    observedGeneration: 3
    readyReplicas: 1
    replicas: 1
    updatedReplicas: 1

## POD Description

    k describe pods python-logger-84774f7c94-4h77q  -n monitoring

    Name:             python-logger-84774f7c94-4h77q
    Namespace:        monitoring
    Priority:         0
    Service Account:  default
    Node:             raspberrypi/192.168.1.95
    Start Time:       Fri, 10 Oct 2025 21:43:59 -0500
    Labels:           app=python-logger
                    job=python-logger
                    pod-template-hash=84774f7c94
    Annotations:      kubectl.kubernetes.io/restartedAt: 2025-10-10T21:43:59-05:00
    Status:           Running
    IP:               10.244.3.29
    IPs:
    IP:           10.244.3.29
    Controlled By:  ReplicaSet/python-logger-84774f7c94
    Containers:
    python-logger:
        Container ID:   containerd://2f42bdb449eef75404ed2c80aa4096eef0682cc0e3bea3fdf38304279a46a716
        Image:          mrangelcruz1960/python-logger:latest
        Image ID:       docker.io/mrangelcruz1960/python-logger@sha256:bd470d27d4c8927f166a9563251423701c8c32d08e9a82c7c95a25f08b94ebe7
        Port:           <none>
        Host Port:      <none>
        State:          Running
        Started:      Fri, 10 Oct 2025 21:44:01 -0500
        Ready:          True
        Restart Count:  0
        Environment:    <none>
        Mounts:
        /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-5vpfq (ro)
    Conditions:
    Type                        Status
    PodReadyToStartContainers   True 
    Initialized                 True 
    Ready                       True 
    ContainersReady             True 
    PodScheduled                True 
    Volumes:
    kube-api-access-5vpfq:
        Type:                    Projected (a volume that contains injected data from multiple sources)
        TokenExpirationSeconds:  3607
        ConfigMapName:           kube-root-ca.crt
        ConfigMapOptional:       <nil>
        DownwardAPI:             true
    QoS Class:                   BestEffort
    Node-Selectors:              <none>
    Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                                node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
    Events:                      <none>

## ROLLOUT THE DEPLOYMENT

    kubectl -n monitoring rollout restart deployment python-logger 


Note: to see the deployment name

    k -n monitoring get deployments
