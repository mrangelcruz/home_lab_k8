## EXPERIMENT 1

1. create namdspace

    kubectl create namespace test-sandbox

2. apply sandbox-limit.yaml

    kubectl apply -f sandbox-limit.yaml

    result:
    limitrange/sandbox-limits created
    resourcequota/sandbox-quota created


3. apply safe-memory-hog.yaml

    kubectl apply -f safe-memory-hog.yaml 
    
    result:
    pod/safe-memory-hog created

4. Observe

    kubectl get pod safe-memory-hog -n test-sandbox -o wide