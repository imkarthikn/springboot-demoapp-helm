# variables projects
REPO = docker.io/
DOCKER_USER = imkarthikn
DOCKER_PASS = ''
NAMEAPP = demoapp
VERSIONAPP = 1.0
NAMECHART = demoapp
#NAMEDB = exdb
#VERSIONDB = 1.0
NAMESPACE = demoapp
export PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/usr/local/bin:$PATH
.PHONY: upgrade prep build build_app build_db push run status clean dry-run purge

prep:
	@#@ Enables deployment of pods to the master node
	kubectl taint nodes --all dedicated- || echo "OK"


build: build_app build_db
	@#@ build docker images. Before you need install docker

build_app:
	docker build -t $(NAMEAPP):$(VERSIONAPP) .

#build_db:
#	cd image_base_db/ && docker build -t  $(NAMEDB):$(VERSIONDB) .

login:
	docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) $(REPO)

#push: login
#	@#@ Push images. Before shove you need to set the variables DOCKER_USER & DOCKER_PASS
#	docker push $(REPO)$(NAMEAPP):$(VERSIONAPP)
#	docker push $(REPO)$(NAMEDB):$(VERSIONDB)

dry-run:
	@#@ dry-run helm projects
	helm install  charts/demo-app/. --dry-run --debug --name $(NAMECHART) --set app.image.repository=$(NAMEAPP),app.image.tag=$(VERSIONAPP) 

run:
	@#@ install helm projects
	helm install  charts/demo-app/. --name $(NAMECHART) --set app.image.repository=$(NAMEAPP),app.image.tag=$(VERSIONAPP) 

upgrade:
	@#@ upgrade helm projects
	helm upgrade $(NAMECHART)  charts/demo-app/. --debug  --set app.image.repository=$(NAMEAPP),app.image.tag=$(VERSIONAPP)

status:
	@#@ status helm projects
	helm status $(NAMECHART)

clean:
	@#@ delete helm projects
	helm delete $(NAMECHART)

purge:
	@#@ Purge helm projects
	helm delete --purge $(NAMECHART)

help:
	@grep -P "\t@#@" $(CURDIR)/Makefile -B 2 | \
	grep -P "^([\w$$]+|\t)" | \
	awk '{if ($$1 ~ /^@?#/) {$$1="\t\t";print;} else print "\033[1;37m" $$1 "\033[0m "}'
