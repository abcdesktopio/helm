doc:
	@echo "==========================================================="
	@echo "make doc		: display this doc"
	@echo "make build		: build helm and lint it"
	@echo "make debug		: generate yaml files"
	@echo "make clean		: clean local helm"
	@echo "make deploy		: install helm"
	@echo "make uninstall		: uninstall helm"
	@echo "==========================================================="

build: clean
	helm package ./abcdesktop/
	@echo "========================================"
	helm lint abcdesktop-0.1.0.tgz
	@echo "========================================"

clean:
	rm -f *.tgz

deploy:
	helm upgrade --install abcdesktop --create-namespace ./abcdesktop-0.1.0.tgz -n abcdesktop

debug:
	helm template --debug ./abcdesktop-0.1.0.tgz > debug-1.yaml
	-helm install --dry-run test ./abcdesktop-0.1.0.tgz > debug-2.yaml

uninstall:
	helm uninstall abcdesktop -n abcdesktop