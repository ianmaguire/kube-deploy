# Kubernetes Deployment Tools
Kubernetes deployment using terraform and a slightly modified incubator/kubespray ansible playbook

#### Setup environment 
```
terraform apply
```

#### Launch application
```
cd kubespray; ansible-playbook cluster.yml
```

---

-	[Travis CI:  
	![build status badge](https://img.shields.io/travis/ianmaguire/kube-deploy/master.svg)](https://travis-ci.org/ianmaguire/kube-deploy/branches)

---