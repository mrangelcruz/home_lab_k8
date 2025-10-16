## Attempt to Install K8 worker (ubuntu) via Ansible

INITIAL STATE:

    k get nodes
    NAME          STATUS   ROLES           AGE    VERSION
    ac-dream      Ready    control-plane   6d1h   v1.29.15
    raspberrypi   Ready    <none>          5d5h   v1.29.15

### We will try to add a second worker (ubuntu)

invoke:

    ansible-playbook -i inventory.ini k8s_worker_setup.yml -e "k8s_version=1.28" --ask-become-pass

When the playbook succeeds:

    k get nodes -A

    NAME            STATUS   ROLES           AGE     VERSION
    ac-dream        Ready    control-plane   6d11h   v1.29.15
    k8-controller   Ready    <none>          5s      v1.29.2
    raspberrypi     Ready    <none>          5d15h   v1.29.15


---

ssh:

    ssh angelcruz@k8-controller

    ssh pi@raspberrypi

