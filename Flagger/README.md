# Flagger - Progressive Delivery Operator for Kubernetes

Flagger was designed to give developers confidence in automating production releases with progressive delivery techniques.

## Canary Release

A benefit of using canary releases is the ability to do capacity testing of the new version in a production environment with a safe rollback strategy if issues are found. By slowly ramping up the load, you can monitor and capture metrics about how the new version impacts the production environment.


Flagger can run automated application analysis, testing, promotion and rollback for the following deployment strategies:

* Canary (progressive traffic shifting with session affinity)
    * Istio, Linkerd, Kuma Service Mesh (opens new - window), Gateway AP
    * Contour, Gloo, NGINX, Skipper, Traefik, Apache APISIX, Knativ

* A/B Testing (HTTP headers and cookies traffic routing)
    * Istio, Gateway API, Contour, NGIN

* Blue/Green (traffic switching and mirroring)
    * Kubernetes CNI, Istio, Linkerd, Kuma, Contour, Gloo, NGINX, Skipper, Traefik, Apache

## GitOps

GitOps is a way to do Kubernetes cluster management and application delivery. It works by using Git as a single source of truth for declarative infrastructure and applications. With Git at the center of your delivery pipelines, developers can make pull requests to accelerate and simplify application deployments and operations tasks to Kubernetes.