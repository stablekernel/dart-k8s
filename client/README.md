## Tour of Heroes: Aqueduct

This is the companion application for the official [Aqueduct tutorial](https://aqueduct.io/docs/tut/getting-started/).

It has been modified from the original [AngularDart tutorial](https://webdev.dartlang.org/angular/tutorial) to make HTTP requests to the Aqueduct tutorial application running on your machine.  

To run this application:

```bash
pub serve
```

A Dockerfile and Kubernetes configuration file is available for deployment. To run on Google Cloud:

```bash
pub build
docker build -t gcr.io/<your-project-name>/tour-of-heroes:latest .
gcloud docker -- push gcr.io/<your-project-name>/tour-of-heroes:latest
kubectl apply -f k8s/
```

This configuration file assumes your cluster has an `nginx-ingress-controller`. To run with Google Cloud Load Balancers, remove the `kubernetes.io/ingress.class: "nginx"` annotation from the Ingress resource.