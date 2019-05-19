# Treasure Hunt

## Aims

To explore kubernetes secrets & configmap.

## Pre-requisites

Docker
minikube
helm
triller
kubectl

## How to Run In Minikube

Start minikube:
 
`minikube start --vm-driver=none`

Build image for minikube - from this directory run

`eval $(minikube docker-env)` <br/>
`docker build . -t demoapp`

Deploy with

`make help`  checkout the commands here
`make run`

First access from: 

`make status`
get the nodeport and add it in VM NAT 

And play by going to e.g. `http://localhost:30080/treasure?x=1&y=1`

Delete with
 
`make delete`

And stop with `minikube stop`

## Or in minikube with Helm

As above but replace the `kubectl create` command with: 

`make run (or) helm install --name=demoapp ./charts/demoapp/`<br/>

Or to set the treasure location then instead:

 `helm install --name=demoapp  --set treasure.location.x=3,treasure.location.y=2 ./charts/demoapp/ `<br/>

And access with:

`minikube service demoapp`

To remove use `helm del --purge demoapp` or make purge
