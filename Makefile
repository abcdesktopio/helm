build:
	
	helm package ./abcdesktop/
	@echo "========================================"
	helm lint abcdesktop-0.1.0.tgz
	@echo "========================================"

clean:
	rm -f *.tgz

deploy:
	helm upgrade --install abcdesktop --create-namespace ./abcdesktop-0.1.0.tgz -n abcdesktop