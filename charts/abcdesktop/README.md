# ABCDesktop helm package

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/abcdesktop)](https://artifacthub.io/packages/search?repo=abcdesktop)

ABCDesktop is a cloud native desktopless service, and a complete work environment accessible from a simple HTML 5 web browser, without any installation. Have a look on https://www.abcdesktop.io/ to get more informations.

## To install

Add repository

```
helm repo add abcdesktop https://abcdesktopio.github.io/helm/
```


Install chart

```
helm install my-abcdesktop abcdesktop/abcdesktop --version 4.4.12 --create-namespace -n abcdesktop
```

## To connect

When install your helm installation process is ready, you need to forward the pod's router tcp port 80 to your localhost port `30443` (for example)

```
LOCAL_PORT=30443
NAMESPACE=abcdesktop
kubectl port-forward $(kubectl get pods -l run=router-od -o jsonpath={.items..metadata.name} -n ${NAMESPACE} ) --address 0.0.0.0 "${LOCAL_PORT}:80" -n ${NAMESPACE}
```

Open your web browser

Open URL [http://localhost:30443](http://localhost:30443)


## ABCDesktop parameters

The following table contains the helm parameters:

| Key                                   | Description                               | Default Value                               |
| ------------------------------------- | ----------------------------------------- | ------------------------------------------- |
| `imagePullSecrets`                    | Secret name to pull images | []              |
| `console.image`                       | Docker image used for the console service | `ghcr.io/abcdesktopio/console`              |
| `console.tag`                         | Docker image tag                          | `4.4`                                       |
| `console.replicaCount`                | Number of replicas for the console        | `1`                                         |
| `console.resources.limits.cpu`        | CPU limit                                 | `0.5`                                       |
| `console.resources.limits.memory`     | Memory limit                              | `128Mi`                                     |
| `console.resources.requests.cpu`      | CPU request                               | `0.1`                                       |
| `console.resources.requests.memory`   | Memory request                            | `16Mi`                                      |
| `memcached.image`                     | Docker image used for Memcached           | `ghcr.io/abcdesktopio/memcached`            |
| `memcached.tag`                       | Docker image tag                          | `4.4`                                       |
| `memcached.replicaCount`              | Number of replicas                        | `1`                                         |
| `memcached.resources.limits.cpu`      | CPU limit                                 | `0.2`                                       |
| `memcached.resources.limits.memory`   | Memory limit                              | `64Mi`                                      |
| `memcached.resources.requests.cpu`    | CPU request                               | `0.1`                                       |
| `memcached.resources.requests.memory` | Memory request                            | `16Mi`                                      |
| `mongo.enabled`                       | Enable/disable MongoDB deployment         | `true`                                      |
| `mongo.keysgenerator.image`           | Docker image for keys generator           | `ghcr.io/abcdesktopio/keysgenerator`        |
| `mongo.keysgenerator.tag`             | Keys generator image tag                  | `4.4`                                       |
| `mongo.keysgenerator.mongodkeylength` | MongoDB keyfile length                    | `756`                                       |
| `mongo.image.repository`              | Docker image repository for MongoDB       | `ghcr.io/abcdesktopio/mongo`                |
| `mongo.image.tag`                     | Docker image tag                          | `safe8.0`                                   |
| `mongo.image.pullPolicy`              | Image pull policy                         | `IfNotPresent`                              |
| `mongo.replicaCount`                  | Number of replica set members             | `1`                                         |
| `mongo.resources.limits.cpu`          | CPU limit                                 | `500m`                                      |
| `mongo.resources.limits.memory`       | Memory limit                              | `512Mi`                                     |
| `mongo.resources.requests.cpu`        | CPU request                               | `100m`                                      |
| `mongo.resources.requests.memory`     | Memory request                            | `128Mi`                                     |
| `mongo.persistence.enabled`           | Enable persistent volume for MongoDB data | `false`                                     |
| `mongo.persistence.storageClass`      | Storage class for persistent volume       | `""`                                        |
| `mongo.persistence.size`              | Persistent volume size                    | `8Gi`                                       |
| `mongo.persistence.mountPath`         | Mount path in container                   | `/data/db`                                  |
| `website.image`                       | Docker image for the website (nginx)      | `ghcr.io/abcdesktopio/oc.nginx`             |
| `website.tag`                         | Docker image tag                          | `4.4`                                       |
| `website.replicaCount`                | Number of replicas                        | `1`                                         |
| `website.resources.limits.cpu`        | CPU limit                                 | `0.5`                                       |
| `website.resources.limits.memory`     | Memory limit                              | `128Mi`                                     |
| `website.resources.requests.cpu`      | CPU request                               | `0.1`                                       |
| `website.resources.requests.memory`   | Memory request                            | `8Mi`                                       |
| `website.autoscaling.enabled`:        | Enable/disable autoscaling                | `false`                                     |
| `website.autoscaling.minReplicas`     | Minimum number of replicas allowed        | `1`                                         |
| `website.autoscaling.maxReplicas`     | Maximum number of replicas allowed        | `100`                                       |
| `website.autoscaling.targetCPUUtilizationPercentage`| CPU utilization percentage to trigger autoscaling | `80`                  |
| `website.autoscaling.targetMemoryUtilizationPercentage`| Memory utilization percentage to trigger autoscaling (commented, not active by default)  | `80` |
| `openldap.enabled`                    | boolean `true` or `false` to enable embedded openldap | `true`                          |
| `openldap.image`                      | Docker image for OpenLDAP                 | `ghcr.io/abcdesktopio/docker-test-openldap` |
| `openldap.tag`                        | Docker image tag                          | `4.4`                                       |
| `openldap.replicaCount`               | Number of replicas                        | `1`                                         |
| `openldap.resources.limits.cpu`       | CPU limit                                 | `0.5`                                       |
| `openldap.resources.limits.memory`    | Memory limit                              | `2048Mi`                                    |
| `openldap.resources.requests.cpu`     | CPU request                               | `0.1`                                       |
| `openldap.resources.requests.memory`  | Memory request                            | `128Mi`                                     |
| `pyos.image`                          | Docker image for PyOS                     | `ghcr.io/abcdesktopio/pyos`                 |
| `pyos.tag`                            | Docker image tag                          | `4.4.alpine_latest`                         |
| `pyos.replicaCount`                   | Number of replicas                        | `1`                                         |
| `pyos.resources.limits.cpu`           | CPU limit                                 | `1`                                         |
| `pyos.resources.limits.memory`        | Memory limit                              | `2048Mi`                                    |
| `pyos.resources.requests.cpu`         | CPU request                               | `0.5`                                       |
| `pyos.resources.requests.memory`      | Memory request                            | `256Mi`                                     |
| `pyos.autoscaling.enabled`:           | Enable/disable autoscaling                | `false`                                     |
| `pyos.autoscaling.minReplicas`        | Minimum number of replicas allowed        | `1`                                         |
| `pyos.autoscaling.maxReplicas`        | Maximum number of replicas allowed        | `100`                                       |
| `pyos.autoscaling.targetCPUUtilizationPercentage`| CPU utilization percentage to trigger autoscaling | `80`                     |
| `pyos.autoscaling.targetMemoryUtilizationPercentage`| Memory utilization percentage to trigger autoscaling (commented, not active by default)  | `80` |
| `router.image`                        | Docker image for the router               | `ghcr.io/abcdesktopio/route`                |
| `router.tag`                          | Docker image tag                          | `4.4`                                       |
| `router.nodePort`                     | Service Node Port                         | `30443` or leave empty/null to disable      |
| `router.replicaCount`                 | Number of replicas                        | `1`                                         |
| `router.resources.limits.cpu`         | CPU limit                                 | `0.5`                                       |
| `router.resources.limits.memory`      | Memory limit                              | `512Mi`                                     |
| `router.resources.requests.cpu`       | CPU request                               | `0.25`                                      |
| `router.resources.requests.memory`    | Memory request                            | `16Mi`                                      |
| `router.autoscaling.enabled`:         | Enable/disable autoscaling                | `false`                                     |
| `router.autoscaling.minReplicas`      | Minimum number of replicas allowed        | `1`                                         |
| `router.autoscaling.maxReplicas`      | Maximum number of replicas allowed        | `100`                                       |
| `router.autoscaling.targetCPUUtilizationPercentage`| CPU utilization percentage to trigger autoscaling | `80`                   |
| `router.autoscaling.targetMemoryUtilizationPercentage`| Memory utilization percentage to trigger autoscaling (commented, not active by default)  | `80` |
| `speedtest.image`                     | Docker image for the Speedtest service    | `ghcr.io/abcdesktopio/oc.speedtest`         |
| `speedtest.tag`                       | Docker image tag                          | `4.4`                                       |
| `speedtest.replicaCount`              | Number of replicas                        | `1`                                         |
| `speedtest.resources.limits.cpu`      | CPU limit                                 | `1`                                         |
| `speedtest.resources.limits.memory`   | Memory limit                              | `128Mi`                                     |
| `speedtest.resources.requests.cpu`    | CPU request                               | `0.1`                                       |
| `speedtest.resources.requests.memory` | Memory request                            | `32Mi`                                      |
| `nodeSelector` | Node selector | {} |
| `od_config`                           | configuration file for abcdesktop         | *default configuration file*                |

Note Secrets and ConfigMap should exists before helm deployment, if not it will be created.

## Build helm from sources

The following commands are required ( installation depends of your operating system):
- **helm**
- **git**

First clone the project on the build host:

~~~ bash
$ git clone https://github.com/abcdesktopio/helm.git
~~~

and move to the project directory:

~~~ bash
$ cd helm/charts/
~~~

and build package:

~~~ bash
$ helm package ./abcdesktop/
Successfully packaged chart and saved it to: abcdesktop-4.4.12.tgz
~~~

The helm file **abcdesktop-4.4.12.tgz** is created.

Let's lint it:

~~~ bash
$ helm lint abcdesktop-4.4.12.tgz
==> Linting abcdesktop-4.4.12.tgz

1 chart(s) linted, 0 chart(s) failed
========================================
~~~

## Install helm package


## Certificates

By default, the helm creates self-signed certificates but you can provide your own before deploying the helm:

First generate your certificates:

~~~ bash
openssl genrsa -out abcdesktop_jwt_desktop_payload_private_key.pem 1024
openssl rsa -in abcdesktop_jwt_desktop_payload_private_key.pem -outform PEM -pubout -out  _abcdesktop_jwt_desktop_payload_public_key.pem
openssl rsa -pubin -in _abcdesktop_jwt_desktop_payload_public_key.pem -RSAPublicKey_out -out abcdesktop_jwt_desktop_payload_public_key.pem
openssl genrsa -out abcdesktop_jwt_desktop_signing_private_key.pem 1024
openssl rsa -in abcdesktop_jwt_desktop_signing_private_key.pem -outform PEM -pubout -out abcdesktop_jwt_desktop_signing_public_key.pem
openssl genrsa -out abcdesktop_jwt_user_signing_private_key.pem 1024
openssl rsa -in abcdesktop_jwt_user_signing_private_key.pem -outform PEM -pubout -out abcdesktop_jwt_user_signing_public_key.pem
~~~

Then create the target namespace in wich abcdesktop will be deployed:

~~~ bash
kubectl create namespace abcdesktop
~~~

and, create the kubernetes secrets from the new key files into the target namespace:

~~~ bash
kubectl create secret generic abcdesktopjwtdesktoppayload --from-file=abcdesktop_jwt_desktop_payload_private_key.pem --from-file=abcdesktop_jwt_desktop_payload_public_key.pem --namespace=abcdesktop
kubectl create secret generic abcdesktopjwtdesktopsigning --from-file=abcdesktop_jwt_desktop_signing_private_key.pem --from-file=abcdesktop_jwt_desktop_signing_public_key.pem --namespace=abcdesktop
kubectl create secret generic abcdesktopjwtusersigning --from-file=abcdesktop_jwt_user_signing_private_key.pem --from-file=abcdesktop_jwt_user_signing_public_key.pem --namespace=abcdesktop
~~~

You can verify secrets creation with the following command :

~~~ bash
kubectl get secrets -n abcdesktop
~~~

You should read on the standard output :

~~~ bash
NAME                          TYPE                                  DATA   AGE
abcdesktopjwtdesktoppayload   Opaque                                2      68s
abcdesktopjwtdesktopsigning   Opaque                                2      68s
abcdesktopjwtusersigning      Opaque                                2      67s
~~~

### Install from online repo

Please install the Helm repository as instructed and run the resynchronization process to ensure all configurations are up-to-date. Follow these steps:

~~~ bash
helm repo add abcdesktop https://abcdesktopio.github.io/helm/
helm repo update
~~~

To list the available versions, run the command:

~~~ bash
helm search repo abcdesktop
NAME                 	CHART VERSION	APP VERSION	DESCRIPTION
abcdesktop/abcdesktop	4.4.12        	4.4.12      	ABCDesktop helm chart
~~~

Then to install:

~~~ bash
helm upgrade --install abcdesktop --create-namespace abcdesktop/abcdesktop -n abcdesktop
~~~

### From local build

~~~ bash
$ helm upgrade --install abcdesktop --create-namespace ./abcdesktop-4.4.12.tgz  -n abcdesktop
~~~

## Customize the default value

- To disable local embedded openldap, if you are using your own ldap directory service

`
helm install --set openldap.enabled=false my-abcdesktop abcdesktop/abcdesktop --version 4.4.12 --create-namespace -n abcdesktop
`


## Uninstall

~~~ bash
$ helm uninstall my-abcdesktop -n abcdesktop
~~~

where **abcdesktop** is the instance name.

## Known limitations

### MongoDB credentials and Helm's `lookup` function

The `secret-mongodb` Secret is generated only once and then reused across
upgrades, so that redeploying the chart does not rotate credentials that are
already in use by a running MongoDB instance. This is implemented in
`templates/mongo-secret.yaml` using Helm's `lookup` function: if the Secret
already exists in the target namespace, its existing password values are
reused; otherwise, new random passwords are generated.

**This mechanism has an important constraint**: `lookup` only works when Helm
has a live connection to the Kubernetes API server. It does **not** work with:

- `helm template`
- `helm install --dry-run` / `helm upgrade --dry-run` (client-side dry-run)
- most GitOps pipelines (ArgoCD, Flux) that render manifests offline before
  applying them

In all of these cases, `lookup` returns an empty result, and the chart will
generate **new random passwords on every render** — even if a Secret with
different values already exists live in the cluster. This can lead to a
mismatch between the rendered Secret and the credentials MongoDB was actually
initialized with.

**Recommendations:**

- When validating this chart in CI, prefer server-side dry-run over a plain
  template render:

```bash
  helm upgrade --install abcdesktop ./charts/abcdesktop --dry-run=server
```

  `--dry-run=server` submits the request to the Kubernetes API server (which
  validates and simulates the change without persisting it), so `lookup`
  behaves correctly — unlike a purely client-side dry-run or `helm template`.

- Never delete the `secret-mongodb` Secret manually unless you also intend to
  reset the underlying MongoDB data (e.g. wipe the persistent volume). Deleting
  the Secret without wiping the data will cause a new random password to be
  generated on the next install, which will no longer match the credentials
  already configured inside MongoDB.

- If your deployment process relies on `helm template` or a client-side
  dry-run as part of a strict GitOps workflow, be aware that credential
  rotation may occur unexpectedly on every render. In that context, consider
  migrating credential management to an external secrets manager (e.g.
  [External Secrets Operator](https://external-secrets.io/) or
  [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)) to make
  Secret generation fully deterministic and independent of `helm template`.

### Password rotation

Rotating MongoDB credentials is **not automatic** and cannot be done by simply
deleting the `secret-mongodb` Secret: the password stored in the Secret must
always match the password actually configured inside MongoDB's own user
store, or authentication will break for every workload connecting to the
database.

To rotate a password, follow this order:
1. Change the password inside MongoDB itself (`db.changeUserPassword(...)`).
2. Update the `secret-mongodb` Secret to match the new value.
3. Restart any workload that reads `MONGODB_URL` from the Secret.

There is currently no automated rotation job in this chart. If your
compliance requirements mandate periodic credential rotation, consider
automating the three steps above in a CronJob, or migrating to an external
secrets manager with native rotation support (see "lookup limitations" above).