# ABCDesktop helm package

ABCDesktop is a cloud native desktopless service, and a complete work environment accessible from a simple HTML 5 web browser, without any installation. Have a look on [https://www.abcdesktop.io/](https://www.abcdesktop.io/) for more informations.



## ABCDesktop parameters


| Name| Description | Value |
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

The following commands are required ( installation depends of your operating system):
- **helm** 
- **git**


First clone the project on the build host:

~~~ bash
git clone https://github.com/abcdesktopio/helm.git
~~~

and move to the project directory:

~~~ bash
cd helm
~~~

and build package:

~~~ bash
helm package ./abcdesktop/
Successfully packaged chart and saved it to: abcdesktop-0.1.0.tgz
~~~

The helm file **abcdesktop-0.1.0.tgz** is created.

Let's lint it:

~~~ bash
helm lint abcdesktop-0.1.0.tgz
==> Linting abcdesktop-0.1.0.tgz

1 chart(s) linted, 0 chart(s) failed
========================================
~~~

##  Install helm package

### From local package

~~~ bash
helm upgrade --install abcdesktop --create-namespace ./abcdesktop-0.1.0.tgz  -n abcdesktop
~~~




## Uninstall

~~~ bash
helm uninstall abcdesktop
~~~

where **abcdesktop** is the instance name.