# ABCDesktop helm package

ABCDesktop is a cloud native desktopless service, and a complete work environment accessible from a simple HTML 5 web browser, without any installation. Have a look on [https://www.abcdesktop.io/](https://www.abcdesktop.io/) for more informations.
## ABCDesktop parameters

The following table contains the helm parameters:

|Name| Description|Value|
|---|---|---|
| image.pullpolicy | default image pull policy | IfNotPresent |
| memcached.image |memcached's image | memcached |
| memcached.tag |memcached's image tag |latest |
| openldap.image |openldap's image | abcdesktopio/oc.openldap |
| openldap.tag |openldap's image tag | 3.0 |
| speedtest.image |speedtest's image | abcdesktopio/oc.speedtest |
| speedtest.tag |speedtest's image tag | 3.0 |
| nginx.image |nginx's image | abcdesktopio/oc.nginx |
| nginx.tag |nginx's image tag | 3.2 |
| mongodb.image |mongodb's image | mongo |
| mongodb.tag |mongodb's image tag | 4.4 |
| pyos.image |pyos's image | oc.pyos |
| pyos.tag |pyos's image tag | 3.2 |
| secrets.jwtsigningkeys| name of the Secret containing signing key | "" |
| secrets.jwtpayloadkeys| name of the Secret containing payload key | "" |
| secrets.jwtusersigningkeys| name of the Secret containing user signing key | "" |
| secrets.jwtdesktopsigning| name of the Secret containing desktop signing key | "" |
| secrets.jwtdesktoppayload| name of the Secret containing desktop payload key | "" |
| config| name of the ABCDesktop ConfigMap containing configuration|""|

Note Secrets and ConfigMap MUST exists before helm deployment.

## Build helm from sources 

## Manual

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
Successfully packaged chart and saved it to: abcdesktop-0.1.0.tgz
~~~

The helm file **abcdesktop-0.1.0.tgz** is created.

Let's lint it:

~~~ bash
$ helm lint abcdesktop-0.1.0.tgz
==> Linting abcdesktop-0.1.0.tgz

1 chart(s) linted, 0 chart(s) failed
========================================
~~~

##  Install helm package

### From local package

~~~ bash
$ helm upgrade --install abcdesktop --create-namespace ./abcdesktop-0.1.0.tgz  -n abcdesktop
~~~

## Uninstall

~~~ bash
$ helm uninstall abcdesktop -n abcdesktop
~~~

where **abcdesktop** is the instance name.





## Makefile

The Makefile is used to build, test, deploy, and manage the abcdesktop Helm chart. It defines several targets for various tasks:

### doc
> `make doc`
> :displays the documentation

The `doc` target is used to display the documentation of this Makefile by 
echoing out a formatted message.

### build
> `make build`
> :builds Helm chart and lints it

The `build` target is used to build the Helm chart and run lint checks on it. This is accomplished through the `clean` and `helm lint` commands.

### clean
> `make clean`
> :removes .tgz files generated during building

The `clean` target is used to remove any `.tgz` files that may have been generated during the build process.

### deploy
> `make deploy`
> :installs Helm chart in a Kubernetes cluster

The `deploy` target is used to install the Helm chart into a Kubernetes cluster. This is accomplished by using the `helm upgrade` command with the `--install` flag, which creates or updates a release. The `-n` flag is used to specify the namespace 
for the deployment.

### uninstall
> `make uninstall`
> :uninstalls Helm chart from a Kubernetes cluster

The `uninstall` target is used to uninstall the Helm chart from a Kubernetes cluster. This is accomplished by using the `helm uninstall` command with the name of the release and namespace.

Usage:
------

To use this Makefile, save it in the root directory of your Helm chart (i.e., the same directory as your `Chart.yaml` file), and then run `make` or specify a target, such as `make build`. For example:

```sh
$ make help # displays available targets
$ make build # builds and lints Helm chart
$ make deploy # installs Helm chart in Kubernetes cluster
$ make uninstall # removes Helm chart from Kubernetes cluster
$ make clean # cleans up generated .tgz files
```
