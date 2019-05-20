#!/bin/bash
yum install ansible git wget -y
yum install ansible elinks vim -y
sudo setenforce 0
yum install -y yum-utils vim telnet git wget
yum install -y yum-utils vim telnet git wget
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install ./epel-release-latest-7.noarch.rpm -y
echo "127.0.0.1 minikube minikube." | sudo tee -a /etc/hosts
status(){
    if [ $? -eq 0 ] ; then
    echo "serivce started"
else
    echo "script failed"
    exit 1;
fi
}
echo "###################################Installing dependencies##########################################################################################"
sudo hostnamectl set-hostname 'k8s-master'
sudo setenforce 0
sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
#sudo systemctl stop firewalld
sudo /usr/sbin/iptables -F
export PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/usr/local/bin:$PATH
sudo swapoff -a && sudo modprobe br_netfilter
sudo yum install socat curl elinks -y
#sudo echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

# Check if docker is installed
if ! command -v docker >/dev/null 2>&1; then
    echo "................................................................docker is not installed and installing it.........................................................................."
    #curl -fsSL https://get.docker.com/ | sh
    sudo yum install -y device-mapper-persistent-data lvm2 && sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && yum -y install docker-ce &&  sudo systemctl start docker &&  sudo systemctl enable docker
elif
   [ `systemctl is-active docker` = "active" ]; then
    echo "..................................................................docker is alive :)................................................................................." ;

else
    echo "..................................................................Activiating docker :)................................................................................" ;
    sudo systemctl start docker && sudo systemctl enable docker
fi


# Check if kubectl is installed
if ! command -v kubectl >/dev/null 2>&1; then
    echo "....................................................................kubectl is not installed and installing it................................................................."
    cat <<'EOF' > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo yum -y install kubelet kubectl
sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo systemctl daemon-reload
sudo systemctl restart kubelet
else
    echo "....................................................................kubectl is installed..............................................................................................."
fi

# Check if minikube is installed
if ! command -v minikube >/dev/null 2>&1 ; then
    echo ".......................................................................minikube is not installed and installing it.........................................................................."
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/sbin/
else
    echo ".......................................................................minikube is installed......................................................................................................"

fi

# Check if helm is installed
if ! command -v helm >/dev/null 2>&1 ; then
    echo ".......................................................................helm is not installed."
    #curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh

   #chmod +x get_helm.sh

   #./get_helm.sh
curl -Lo helm.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz && tar -xvzf helm.tar.gz && chmod +x linux-amd64/helm && sudo mv linux-amd64/helm /usr/local/sbin/
else

    echo ".........................................................................helm is installed.................................................................................................."
fi

# Ensure that minikube is running
if ! minikube ip >/dev/null 2>&1 ; then
    echo "Starting minikube cluster..."

    minikube start -v 4 --vm-driver=none --bootstrapper kubeadm
    printf "Waiting for minikube"
    #until [[ `minikube status | grep -i "apiserver: Running"` > /dev/null 2>&1 ]]; do
     #  printf "."
      # sleep 3
    #done
    #sleep 300
    status
    minikube status

fi

# Install helm on cluster
minikube status | grep -i "apiserver: Running"  > /dev/null 2>&1
result=$?
if [ "${result}" -eq "0"  ]; then
#if ! helm list >/dev/null 2>&1 ; then
    echo "Installing helm..."
    kubectl -n kube-system create sa tiller

    kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

    helm init --service-account tiller

    printf "Waiting for Helm"
    until helm list >/dev/null 2>&1
    do
      printf "."
      sleep 3
    done
    printf "\n"
#fi
else
   printf "minikube not started"
   exit 1
fi

# Output debug logs
echo "...............................................................................---------- Debug ----------........................................................................."
minikube version
minikube status
printf "K8S "
kubectl version --client --short
printf "K8S "
kubectl version --short | grep Server
printf "Helm "
helm version --short -c
printf "Helm "
helm version --short -s
echo "K8s cluster and dependencies installed"
echo "---------------------------....................................................................APP Install.............................................................................."
cd /usr/local/src
git clone https://github.com/imkarthikn/springboot-demoapp-helm.git
cd springboot-demoapp-helm
echo "................................................................................................docker build............................................................................."
make build
#printf "Waiting for docker built"
 #   until docker images | grep -i demoapp >/dev/null 2>&1
  #  do
   #   printf "."
    #  sleep 3
    #done
    #printf "\n"
sleep 20
make run
sleep 10
echo ".........................................................................................................k8 dashboard.........................................................................."
#helm install stable/kubernetes-dashboard --namespace kube-system --set service.type=NodePort --name dash
helm install stable/kubernetes-dashboard --namespace kube-system --name dash -f /usr/local/src/springboot-demoapp-helm/charts/values.yaml
echo "\n ..............................................................................helm  application list......................................................................................\n "
helm list



a=`helm status demoapp | grep -a2 v1/Service | grep TCP | awk -F ":" '{print $2}' | awk '{print $1}'`
b=`helm status dash | grep -a2 v1/Service | grep TCP | awk -F ":" '{print $2}' | awk '{print $1}'`

echo "------------------------------>                    NAT PORT TO ACCESS THE APPLICATION is $a  ( configure it in VM network setting )            <------------------------------------------------------   "
echo "------------------------------>                    NAT PORT TO ACCESS THE k8's Dashboard is $b  ( configure it in VM )            <------------------------------------------------------   "
