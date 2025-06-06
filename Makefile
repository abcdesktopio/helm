doc:

clean:
	-rm -f *.tgz

build: clean
	helm package abcdesktop

lint:


deploy: build
	helm upgrade my-abcd ./abcdesktop-4.0.0.tgz -f values.yaml --create-namespace --namespace abcdesktop --install
undeploy:
	helm uninstall my-abcd --namespace abcdesktop