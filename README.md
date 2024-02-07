# ABCDesktop helm package

ABCDesktop is a cloud native desktopless service, and a complete work environment accessible from a simple HTML 5 web browser, without any installation. Have a look on [https://www.abcdesktop.io/](https://www.abcdesktop.io/) for more informations.


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