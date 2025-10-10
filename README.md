# home_lab_k8

## Launch cluster via Terraform

    terr init
    terr fmt
    terr validate
    terr plan
    terr apply -auto-approve

The terraform state is uploaded to S3, and tfstate lock is regsitered in dynamodb, both in us-west-2 region.

### Raspberry Pi join the cluser

#### On the Controller:

    scp join-k8s-pi.sh pi@raspberrypi:/home/pi/

#### On the Raspberry Pi:

    ssh pi@raspberrypi
    ./join-k8s-pi.sh

#### On the Controller

    ./patch-flannel.sh


#### On the Raspberry Pi:

    ssh pi@raspberrypi
    ./join-k8s-pi.sh

##### NOTE:
ignore install-k8s-pi.sh (this sets up a controller on the raspberry pi)

