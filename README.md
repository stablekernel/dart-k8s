# Deploying a full stack Dart application on Google Cloud using Docker and Kubernetes

This blog post is going to cover a deployment process for a full stack Dart application.
For the front end we will be using [AngularDart](https://webdev.dartlang.org/angular/) and for the backend [Aqueduct](https://aqueduct.io).
I'm not going to be getting into the Dart code itself, just the deployment. Both frameworks have tutorials of their own: [Angular here](https://webdev.dartlang.org/angular/tutorial) and [Aqueduct here](https://aqueduct.io/docs/tut/getting-started/).

We will be using Docker to containerize both apps, ensuring that they can run reliably anywhere.
Then we will use Kubernetes to deploy the apps to Google Cloud. 

If you're unfamiliar with Kubernetes, it would be good to read [this blog post](https://stablekernel.com/an-introduction-to-kubernetes/) first.

# Google Cloud

Google Cloud Platform is Google’s infrastructure as a service. You get a $300 credit for signing up, so you can give it a full run through before deciding if it works well for you.
Docker and Kubernetes are platform independent, making it easy to move your apps around if you need to change later.

Head over to [Google Cloud Platform](https://cloud.google.com) and sign in or create an account.
You have to give credit card information when signing up, but Google does not start automatically charging your card when the trial runs out. They will email you and ask your permission first.
Once you've created your account, make sure you're in the [console](https://console.cloud.google.com) and select the menu in the top left corner and select `Home`.
There you should see project details for the default project that they set up for you, click on `Go to project settings` for the project.
You can rename this project whatever you'd like, but you can't change its ID. 
You are going to be using this ID in a lot of places and you're going to want it to be something easy for you to remember, instead of that default one.
I'd recommend deleting this project (by selecting `SHUT DOWN`) and creating a new one with an ID of your choice.

# Tools

Ok, now that we have a Google Cloud account set up, let's get all of our tools set up.
All of these tools have good installation instructions for whatever kind of machine you're on.

#### Docker: 

Head over to https://www.docker.com/get-docker and follow the installation instructions.
Once you get it installed, go ahead and start running it.

#### Google Cloud SDK:

Installation instructions for Cloud SDK [here](https://cloud.google.com/sdk/docs/quickstarts).
Follow all the way through the instructions, including getting logged in from the terminal `gcloud` command and selecting the project you just set up.

#### Kubectl (Kubernetes Command-Line Tool):

Instructions for kubectl are [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/). There are several different options, but the easiest one is using the Google Cloud SDK that you just installed.

#### Tutorial Sample Code:

Now that we've got all of the tools you'll need, go ahead and download the [sample code](https://github.com/stablekernel/dart-k8s) for this tutorial.
There are two top level directories in this project. `client` is the Angular application and `server` is the Aqueduct application.
 
# Building Docker Images

We are going to start by building a Docker image of the Angular application. Inside the `client` directory you will see a `Dockerfile`.
This is what we use to build our image.

If you take a look at the [`Dockerfile`](https://github.com/stablekernel/dart-k8s/blob/master/client/Dockerfile) there are a couple things going on:

First we are creating a build environment container, where we use [pub](https://pub.dartlang.org/) (Dart's package manager) to download the app's dependencies and then build the application.
[Here's Google's documentation](https://hub.docker.com/r/google/dart/) on their `google/dart` Docker image and why you need to run `pub get` twice.

Then we are copying in our build folder into an already existing nginx Docker container. Most of the rest of this is just set up to [make the container not run as root](http://pjdietz.com/2016/08/28/nginx-in-docker-without-root.html) as a [security precaution](https://www.youtube.com/watch?v=BznjDNxp4Hs).

The one other thing that is worth pointing out, is in the [`default.conf`](https://github.com/stablekernel/dart-k8s/blob/master/client/default.conf) file that we use for configuring nginx.

`try_files $uri $uri/ /index.html;`

This will route any files that it can't find back to our `index.html` allowing us to use the Angular router without needing the `HashLocationStrategy` that you see in the [default Angular Heroes tutorial](https://webdev.dartlang.org/angular/tutorial).

To build a Docker image using this file, in your terminal `cd` into the `client` directory and run:

`$ docker build -t gcr.io/$PROJECT_ID/angular-heroes:latest .`

where `PROJECT_ID` is the ID of the project you set up in Google Cloud. `gcr` is [Google's Container Registry](https://cloud.google.com/container-registry/), which we will set up in just a moment. 
`angular-heroes` is the name of our image, and `latest` is a tag that we are adding to the image. 
Generally it would be better to tag each build with something specific that would help you identify that build, like a git commit hash, but I'm taking some shortcuts for this tutorial :)

Head back into the Google Cloud Console, click the top left menu again, and go to [`Tools > Container Registry`](https://console.cloud.google.com/gcr).
Click the "Enable Container Registry" button. After it finishes getting set up, go back to the command line and push your container up to the registry:

`$ gcloud docker -- push gcr.io/$PROJECT_ID/angular-heroes:latest`

again replacing `$PROJECT_ID` with your project ID.

After it pushes up, go back to the Google Cloud Console and click the `REFRESH` button. You should now see your Docker image.

# Kubernetes

Kubernetes (abbreviated as k8s) is an open source deployment platform developed by Google.
In going through the deployment of our full stack application, we'll get a look at most of its different pieces.

The first thing you need to do is to enable Kubernetes in the Google Cloud Console. 
From the menu go to [`Compute > Kubernetes Engine > Kubernetes Clusters`](https://console.cloud.google.com/kubernetes/list).  
After navigating to this page it will take a few minutes for Google Cloud to set up Kubernetes. Once it has, click the "Create cluster" button.
The default settings for the cluster are fine, although you may want to change your location (zone) somewhere closer to you.
Create the cluster, which again will take a few minutes.

Once the cluster is set up, click the `Connect` button and copy the gcloud command into your terminal. It should look something like:

`$ gcloud container clusters get-credentials your-cluster-name --zone your-zone-name --project your-project-name`

This gets the Google Cloud SDK to set up Kubernetes to connect to your project.

To get the Angular application into Google Cloud the first thing we are going to do is to push a Deployment for it up to Kubernetes.
Edit the `client/k8s/deployment.yaml` file in the project to use the name of your docker image that you just pushed up (You should just need to replace $PROJECT_ID with your project's ID).

After you've saved the file, go back to the terminal where we will use `kubectl` to create that deployment:

`$ kubectl apply -f k8s/deployment.yaml`

Back in the Cloud Console, still in the `Kubernetes Engine` section of the menu, go to `Workloads` where you should see the deployment that you just added through `kubectl`.
 
Your Angular Docker image is now running in a pod in your Kubernetes cluster, but there is nothing exposing the deployment anywhere outside of the cluster.
To do this, we are going to add a LoadBalancer service which will get an external IP address.
 
`$ kubectl apply -f k8s/load-balancer/service.yaml`

After you've done this you should be able to see the service in the Cloud Console as well, in the Discovery & load balancing section of the Kubernetes Engine menu.
You can also check out your services and deployments using the command line tool:

`$ kubectl get deployments`    

`$ kubectl get services`
  
For your service you should see an external IP address. It might still say `pending`, in which case just wait a minute and try again.
Once you've got the IP address, enter it in your browser and you should see the sample Angular app!

Load balancer services are one way of exposing deployments, and the quickest one for us to see results with, but what we are going to actually use in this tutorial to expose our different applications are ingresses.
An ingress is a collection of rules that allow inbound connections to reach the cluster services.

Before setting this up, let's go ahead and delete the service we just created:

`$ kubectl delete service web-service`

Now we are going to add a new service, that does not have anything configured to get it an external IP address. We also need to add an ingress. Both of these are in the project's client/k8s/ingress directory.
Before applying these files, remove the host from the ingress.yaml so that the spec looks like:
```
spec:
  rules:
  - http:
      paths:
      - path: /
        backend:
          serviceName: web-service
          servicePort: 80
``` 
We can apply all the files in this directory together:

`$ kubectl apply -f k8s/ingress`

Since an ingress is just a collection of rules, we still need a service to interpret these rules: an ingress controller. Which we've got in client/k8s/ingress-controller. No changes to these files are necessary, just go ahead and apply them as well.

`$ kubectl apply -f k8s/ingress-controller`

To see this ingress controller you will need to do something slightly different:

`$ kubectl get services --all-namespaces`

Namespaces can be used to help keep applications living in the same Kubernetes cluster separate. So far we haven't been adding a namespace to our services, and after running that last command you can see that they just went into the default namespace.
We only need a single ingress controller to handle all ingresses in any namespace, so we added this to our kube-system namespace. Go to the external IP address for the ingress controller (you might need to wait a minute until this is available).
This time you get routed to https and should see a warning about the site not being secure. (it's fine to continue to see the angular app again) By default when we do not give a host to an ingress, our ingress controller is going to try to use HTTPS.

Right now the external IP address your ingress controller is using is ephemeral, and not guaranteed to stay the same. Let's make it static instead.
Go back into the Cloud Console to [`Networking > VPC Network > External IP Addresses`](https://console.cloud.google.com/networking/addresses/list).
Find the IP address from your ingress controller, change ephemeral to static and name the IP address (this is also an object you can access through Kubernetes).

To be able to use HTTP, let's get a host set up. If you don't have a domain name that you can create records for skip ahead to [Aqueduct](#aqueduct), everything will still work, you'll just have to put up with some browser security warnings.

Add an A record in the DNS settings of whatever domain you'd like to use, pointing to your ingress controller's IP address. So for example, an A record from host `heroes` of `mysite.com`.
Next go back into `client/k8s/ingress/ingress.yaml` and add back the host property, so that it's spec would now look like:
```
spec:
  rules:
  - host: heroes.mysite.com
    http:
      paths:
      - path: /
        backend:
          serviceName: web-service
          servicePort: 80
```
  
After you've saved this, reapply the ingress.yaml file to update it.

`$ kubectl apply -f k8s/ingress/ingress.yaml`

Once your A record is active, you should now be able to see the Angular app at that host.

For doing this same setup using HTTPS, [check out this post](https://stablekernel.com/ssl-termination-load-balancing-kubernetes-clusters/).

# Aqueduct

Now let's add our Aqueduct backend application. There are a few more moving pieces involved here since we will also be setting up a database, but the steps should all feel familiar.

The first new piece that we will need for the database are configurations: Config Maps and Secrets. These are ways to store environment variables to be used by different deployments.
Change your terminal's directory from `client` to `server` and inside the `server/k8s` directory you will see a config directory where we have our configurations.
In `config.yaml` are some environment vars for the postgres database: username, database name, and a location for the data (in the postgres docker image we will set up). These values are already set up and do not need to be changed.
In `secrets.yaml` you will need to create a password for your database's user. When using a secrets yaml file, all of the values have to be base64 encoded. You also should not check your secrets file into source control. Create a password, base64 encode it and add it to secrets.yaml for POSTGRES_PASSWORD.

`$ echo -n "whateverpasswordyouwanttouse" | base64`

Once you've got this saved, push up both config files.

`$ kubectl apply -f k8s/config`

You can also check these out in the Cloud Console at [`Compute > Kubernetes Engine > Configuration`](https://console.cloud.google.com/kubernetes/config).

Kubernetes manages creating and destroying pods with your Docker images as needed, but for your database, you don't want the data destroyed and recreated.
We need to get some disk space to persist the database's data. We can do this using a volume claim.
You can look at the Kubernetes file for one of those at `k8s/db/volume-claim.yaml`, this is good to go as it is, or you can change how much disk space you need.

`$ kubectl apply -f k8s/db/volume-claim.yaml`

You can see your volume claims in the Cloud Console at [`Compute > Kubernetes Engine > Storage`](https://console.cloud.google.com/kubernetes/storage).
Now that we've got the volume claim, we are going to use a Postgres Docker image to make a Deployment for our database.

`$ kubectl apply -f k8s/db/deployment.yaml`

If you look into that `deployment.yaml` file, you can see where the volume claim is being used to create a volume, and the mount path that corresponds with the PGDATA variable in our ConfigMap.
You can also see how we link in our ConfigMap and Secrets objects:

```
envFrom:
  - secretRef:
      name: secrets
  - configMapRef:
      name: config
```

We also want a service for this deployment. Like our service / deployment pair for the Angular app, you can see that the service's selectors match the deployment's labels, which is how it knows which deployment to use.

`$ kubectl apply -f k8s/db/service.yaml`

Now let's deploy the Aqueduct application. This will be the same process as the Angular app, but we won't need to go through the extra set up this time.

First do a docker build (making sure you're in the `server` directory now, and again replacing `$PROJECT_ID` with your project's ID).

`$ docker build -t gcr.io/$PROJECT_ID/aqueduct-heroes:latest .`

Aqueduct's [`Dockerfile`](https://github.com/stablekernel/dart-k8s/blob/master/server/Dockerfile) looks similar to our build environment from the Angular Docker file: using pub to get dependencies and link them up (with a different dance this time to make sure the image can run without root permissions).
The entry point for this image uses `pub` to serve the Aqueduct application, using the `k8s-config.yaml` Aqueduct configuration file. If you open this up, you'll see our environment variables again. 
Also in this file, you'll see that the host is just `db-service`, the name of the service we just created for our database.
Inside the Kubernetes cluster, each service has a DNS record set up using its name, which makes it really easy to swap out these different pieces later.

Next we will push the Aqueduct Docker image up to our container registry.

`$ gcloud docker -- push gcr.io/$PROJECT_ID/aqueduct-heroes:latest`

Go into `server/k8s/api/deployment.yaml` and update the image name to your project, and then push up the api deployment and service.

`$ kubectl apply -f k8s/api/`

And to expose the api service, we will need to update our ingress. The ingress configuration file in the server project `server/k8s/ingress/combined-ingress.yaml` has rules for both the web-service and the api-service.
So any calls coming in with a base path of `/api` will be router to the Aqueduct server, and all others will go to our Angular application.  
The sample Angular app in this project is using a relative URL of `/api/heroes` for all of it's networking calls, and the Aqueduct router also has a base path of `/api` to make this work. You could just as easily host the two applications in different places using absolute URLs.

Change the `host` for the two rules to be your hostname (or if not doing this, just remove the host from each) and then apply the ingress.

`$ kubectl apply -f k8s/ingress`

Since this ingress has the same name as the other we created, this will just update the existing ingress.

To check to see if the server is up, go to your host / IP address with a path of `/api/health` (`http://heroes.mysite.com/api/health`). You should see a "Status OK" message. 
Now let’s try to see a list of heroes by going to `/api/heroes`. You should be seeing a Postgres error message. This is because we have an empty database that has not been set up for Aqueduct yet. 
In the `server/k8s/tasks` directory there is a Kubernetes file for running a database migration. 
This object is just a bare Pod, not tied to a specific deployment. It has references to the ConfigMap and Secrets for connecting to the database and will use your same Aqueduct Docker image for running the migration, but with a different entry point so that it does not actually run the Aqueduct server.
Update your image name in the file and then apply it.

`$ kubectl apply -f k8s/tasks/migration-upgrade-bare-pod.yaml`

Then let's go look at all of the pods.

`$ kubectl get pods`

You, most likely, won't see the migration Pod, as this task should finish very quickly. To see all pods, including ones that are no longer running to you can instead do:

`$ kubectl get pods -a`

Now you should be able to see it, with a name of db-upgrade-job and a completed status. Let's take a look at its logs.

`$ kubectl logs db-upgrade-job`

You should see successful output from an Aqueduct database migration. This pod has done its job, run and won't run again, so let's go ahead and delete it.

`$ kubectl delete pod db-upgrade-job`

Now that we've got our database set up properly, try to make the heroes call again, instead of an error, now you should be seeing an empty JSON array. 

Go back to where you have the website hosted and now you should be able to add and view heroes!

# Conclusion

That’s everything it takes to deploy a full stack Dart application to Google Cloud using Docker and Kubernetes! 
Kubernetes deployments can be easier or more complicated depending on your needs. The platform itself is extremely robust and makes it easy to make changes as needed.
Kubectl itself offers a lot of conveniences to make deployments easier than this, I used all yaml files in this post to try to make the concepts clearer.

To learn more about Kubernetes visit:

https://kubernetes.io/docs/tutorials/
https://cloud.google.com/kubernetes-engine/docs/tutorials/
https://github.com/stablekernel/kubernetes
