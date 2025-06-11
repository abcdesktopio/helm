# ABCDesktop helm package

ABCDesktop is a cloud native desktopless service, and a complete work environment accessible from a simple HTML 5 web browser, without any installation. Have a look on https://www.abcdesktop.io/ for more informations.

## ABCDesktop parameters

The following table contains the helm parameters:

| Key                                   | Description                               | Default Value                               |
| ------------------------------------- | ----------------------------------------- | ------------------------------------------- |
| `console.image`                       | Docker image used for the console service | `ghcr.io/abcdesktopio/console`              |
| `console.tag`                         | Docker image tag                          | `"4.0"`                                     |
| `console.replicaCount`                | Number of replicas for the console        | `1`                                         |
| `console.resources.limits.cpu`        | CPU limit                                 | `0.5`                                       |
| `console.resources.limits.memory`     | Memory limit                              | `128Mi`                                     |
| `console.resources.requests.cpu`      | CPU request                               | `0.1`                                       |
| `console.resources.requests.memory`   | Memory request                            | `16Mi`                                      |
| `memcached.image`                     | Docker image used for Memcached           | `ghcr.io/abcdesktopio/memcached`            |
| `memcached.tag`                       | Docker image tag                          | `latest`                                    |
| `memcached.replicaCount`              | Number of replicas                        | `1`                                         |
| `memcached.resources.limits.cpu`      | CPU limit                                 | `0.2`                                       |
| `memcached.resources.limits.memory`   | Memory limit                              | `64Mi`                                      |
| `memcached.resources.requests.cpu`    | CPU request                               | `0.1`                                       |
| `memcached.resources.requests.memory` | Memory request                            | `16Mi`                                      |
| `mongo.image`                         | Docker image for MongoDB                  | `ghcr.io/abcdesktopio/mongo`                |
| `mongo.tag`                           | Docker image tag                          | `"4.4"`                                     |
| `mongo.replicaCount`                  | Number of replicas                        | `1`                                         |
| `mongo.resources.limits.cpu`          | CPU limit                                 | `0.5`                                       |
| `mongo.resources.limits.memory`       | Memory limit                              | `512Mi`                                     |
| `mongo.resources.requests.cpu`        | CPU request                               | `0.1`                                       |
| `mongo.resources.requests.memory`     | Memory request                            | `128Mi`                                     |
| `website.image`                       | Docker image for the website (nginx)      | `ghcr.io/abcdesktopio/oc.nginx`             |
| `website.tag`                         | Docker image tag                          | `"4.0"`                                     |
| `website.replicaCount`                | Number of replicas                        | `1`                                         |
| `website.resources.limits.cpu`        | CPU limit                                 | `0.5`                                       |
| `website.resources.limits.memory`     | Memory limit                              | `128Mi`                                     |
| `website.resources.requests.cpu`      | CPU request                               | `0.1`                                       |
| `website.resources.requests.memory`   | Memory request                            | `8Mi`                                       |
| `openldap.image`                      | Docker image for OpenLDAP                 | `ghcr.io/abcdesktopio/docker-test-openldap` |
| `openldap.tag`                        | Docker image tag                          | `master`                                    |
| `openldap.replicaCount`               | Number of replicas                        | `1`                                         |
| `openldap.resources.limits.cpu`       | CPU limit                                 | `0.5`                                       |
| `openldap.resources.limits.memory`    | Memory limit                              | `2048Mi`                                    |
| `openldap.resources.requests.cpu`     | CPU request                               | `0.1`                                       |
| `openldap.resources.requests.memory`  | Memory request                            | `128Mi`                                     |
| `pyos.image`                          | Docker image for PyOS                     | `ghcr.io/abcdesktopio/pyos`                 |
| `pyos.tag`                            | Docker image tag                          | `"4.0"`                                     |
| `pyos.replicaCount`                   | Number of replicas                        | `1`                                         |
| `pyos.resources.limits.cpu`           | CPU limit                                 | `1`                                         |
| `pyos.resources.limits.memory`        | Memory limit                              | `2048Mi`                                    |
| `pyos.resources.requests.cpu`         | CPU request                               | `0.5`                                       |
| `pyos.resources.requests.memory`      | Memory request                            | `256Mi`                                     |
| `router.image`                        | Docker image for the router               | `ghcr.io/abcdesktopio/route`                |
| `router.tag`                          | Docker image tag                          | `"4.0"`                                     |
| `router.replicaCount`                 | Number of replicas                        | `1`                                         |
| `router.resources.limits.cpu`         | CPU limit                                 | `0.5`                                       |
| `router.resources.limits.memory`      | Memory limit                              | `512Mi`                                     |
| `router.resources.requests.cpu`       | CPU request                               | `0.25`                                      |
| `router.resources.requests.memory`    | Memory request                            | `16Mi`                                      |
| `speedtest.image`                     | Docker image for the Speedtest service    | `ghcr.io/abcdesktopio/oc.speedtest`         |
| `speedtest.tag`                       | Docker image tag                          | `"4.0"`                                     |
| `speedtest.replicaCount`              | Number of replicas                        | `1`                                         |
| `speedtest.resources.limits.cpu`      | CPU limit                                 | `1`                                         |
| `speedtest.resources.limits.memory`   | Memory limit                              | `128Mi`                                     |
| `speedtest.resources.requests.cpu`    | CPU request                               | `0.1`                                       |
| `speedtest.resources.requests.memory` | Memory request                            | `32Mi`                                      |
| `od_config`                           | configuration file for abcdesktop         | *default configuration file*                |

Note Secrets and ConfigMap MUST exists before helm deployment.

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
$ cd helm
~~~

and build package:

~~~ bash
$ helm package ./abcdesktop/
Successfully packaged chart and saved it to: abcdesktop-4.0.0.tgz
~~~

The helm file **abcdesktop-4.0.0.tgz** is created.

Let's lint it:

~~~ bash
$ helm lint abcdesktop-4.0.0.tgz
==> Linting abcdesktop-4.0.0.tgz

1 chart(s) linted, 0 chart(s) failed
========================================
~~~

## Install helm package

### From local package

~~~ bash
$ helm upgrade --install abcdesktop --create-namespace ./abcdesktop-4.0.0.tgz  -n abcdesktop
~~~

## Uninstall

~~~ bash
$ helm uninstall abcdesktop -n abcdesktop
~~~

where **abcdesktop** is the instance name.