#!/usr/bin/env bash

# Steps to install and configure Jenkins
sudo apt-get -y install wget
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get -y install jenkins

# Add some pip’s for python so jjb can compile correctly.
sudo apt-get -y install python-pip
sudo pip install pyyaml
sudo pip install pbr
sudo pip install python-jenkins
sudo pip install setuptools
sudo pip install ordereddict

# Run the following to build the jjb
sudo pip install jenkins-job-builder

git config --global user.email "deepak.dt@gmail.com"
git config --global user.name "Deepak Tiwari"

#echo "******************************************************"
#echo "Configure SSH keys for github" - NOT REQUIRED
#echo "******************************************************"
#echo "Check for existing ssh keys...."
#keys_count=$(ls -al ~/.ssh | grep id_rsa | wc -l)
#if [ $keys_count = 0 ] 
#then
#    echo "No existing ssh keys found....Generating a new ssh key...."
#    ssh-keygen -t rsa -b 4096 -C "deepak-dt@github.com"
#else
#    echo "Existing ssh key found....Reusing..."
#fi
#
#eval $(ssh-agent -s)
#ssh-add ~/.ssh/id_rsa
#
#echo "Key to register to github is :"
#cat ~/.ssh/id_rsa.pub
#
#read -p "Please add above ssh-key to your github account. Press y to continue or n to abort [y/n] : " yn
#case $yn in
#    [Nn]* ) echo "SSH key not registered to github account...Aborting...."; exit;;
#esac
#
#ssh -T git@github.com

########################################################################
# Configure Github, github authentication, github integration plug-ins
########################################################################
#read -p "Please configure Jenkins through GUI [Configure Github, github authentication, github integration plug-ins]. Press y to continue or n to abort [y/n] : " yn
#case $yn in
#    [Nn]* ) echo "Jenkins not configured...Aborting...."; exit;;
#esac

####################################

export WORKSPACE=$PWD
export DEFAULT_ADMIN_PASSWD=`sudo cat /var/lib/jenkins/secrets/initialAdminPassword`

mkdir $WORKSPACE/jenkins-jobs
cat > $WORKSPACE/config.ini << EOF
[jenkins]
user=admin
password=$DEFAULT_ADMIN_PASSWD
url=http://127.0.0.1:8080
query_plugins_info=False
EOF

mkdir $WORKSPACE/jobs

cat > $WORKSPACE/jobs/default.yaml << EOF
- defaults:
    name: global
    logrotate:
        daysToKeep: 300
        numToKeep: 150
        artifactDaysToKeep: -1
        artifactNumToKeep: -1
EOF

cat > $WORKSPACE/jobs/template.yaml << EOF
- job-template:
    name: '{name}_job'
    description: 'Automatically generated test'
    project-type: freestyle
    builders:
        - shell: '{command}'
        #- shell: |
        #    cat > $WORKSPACE/config.ini << EOF
        #    [jenkins]
        #    user=admin
        #    password=c7e9d411f793f45b679eb4ceeadcf08e
        #    url=http://127.0.0.1:8080
        #    query_plugins_info=False
        #    EOF
        #
        #    jenkins-jobs --conf $WORKSPACE/config.ini --ignore-cache update --delete-old jobs
    scm:
    - git:
        url: https://github.com/deepak-dt/vagrant-ansible.git
        branches:
          - master
          - stable
        browser: githubweb
        browser-url: https://github.com/deepak-dt/vagrant-ansible.git
        timeout: 60
        git-config-name: 'Deepak Tiwari'
        git-config-email: 'deepak.dt@gmail.com'
        changelog-against:
          remote: origin
          branch: master
        #force-polling-using-workspace: true
        #merge:
        #    remote: origin
        #    branch: master
        #    strategy: recursive
        #    fast-forward-mode: FF_ONLY
    triggers:
        #- pollscm: "H/30 * * * *"
        #- github
        - pollscm: "* * * * *"
        #- pollurl:
        #    cron: '* * * * *'
        #    urls:
        #        - url: 'https://github.com/deepak-dt/vagrant-ansible'
        #          proxy: false
        #          timeout: 442
        #          check-etag: false
        #          check-date: true
        #          #check-content:
        #          #    - simple: true
    publishers:
      - email:
          recipients: deepak.tiwari@aricent.com
EOF

cat > $WORKSPACE/jobs/projects.yaml << EOF
- project:
    name: project-example
    jobs:
        - '{name}_job':
            name: getspace
            command: df -h
        - '{name}_job':
            name: listEtc
            command: ls /etc
EOF

cd $WORKSPACE
jenkins-jobs --conf $WORKSPACE/config.ini update --delete-old jobs

########################################################################
# TO BE ENHANCED - automate initial Jenkins plungins installation
########################################################################
# wget localhost:8080/jnlpJars/jenkins-cli.jar
# java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin [SOURCE] ... -deploy -restart

########################################################################
# 1. Configure Github repo to use Jenkins plug-in
# 2. Configure Jenkins through GUI [enable additional plug-in for Github]
# 3. Install additional plug-ins - github authentication, github integration
########################################################################
########################################################################