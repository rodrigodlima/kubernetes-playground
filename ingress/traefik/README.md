# Traefik ingress controler

## Prerequisites:

* Helm
* Kubectl
* Kubernetes Cluster Running (Here in my example, I'm using Kind)

## Configuration

```
➜ helm repo add traefik https://helm.traefik.io/traefik
➜ helm repo update
➜ helm install traefik traefik/traefik --create-namespace --namespace=traefik --values=values.yaml
```
