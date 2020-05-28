## Docker Based Examples
This module provides docker compose files for the various architectures for experimentation purposes. This gives you the ability to stand up an entire PE stack in order to learn how this module and HA works. If you have docker and docker-compose you can start up a full Puppet architecture with a single command.  Please note that Puppet does not support PE on containers in production.  

In order to decouple Bolt from a dev system, a special bolt container is created that will run all the bolt commands.  This is
required to achieve maximum portability.  Should you want to run bolt commands against the PE stack you must
first login to this bolt container via ssh, docker or docker-compose.

Example: `docker-compose run --entrypoint=/bin/bash bolt`

### Requirements
To run the container based examples you will need the following requirements:

2. Docker
3. Docker compose
4. 16GB memory, 24GB+ for XL and XL-HA architectures
5. CPU with many cores (Tested with Core i7 6700)

### Starting the example
We have provided a provision.sh script to help making these examples simple.
To use perform the following:

1. cd spec/docker
2. bash provision.sh
3. select desired architecture when prompted (ie. extra-large-ha )
4. Wait 10-20 minutes for provisioning to complete

```
Please choose a PE architecture to build: 
1) extra-large/     3) large/           5) standard/
2) extra-large-ha/  4) large-ha/        6) standard-ha/
#?  
```

### Stopping the example
In order to stop and remove the containers you will need to perform the following.

1. cd spec/docker
2. `cd <chosen architecture>` 
3. docker-compose down

### Logging into the console
You can login to the PE Console after successful provision.  However, first you will need to 
grab the mapped port number of the PE console.  The port numbers are mapped dynamically as to not
cause port conflicts on your system. To see how the ports are mapped you can view them via:

1. docker ps
    ```
    80c6f0b5525c        pe-base             "/sbin/init"        2 hours ago         Up 2 hours          0.0.0.0:32774->22/tcp, 0.0.0.0:32773->443/tcp, 0.0.0.0:32772->4433/tcp, 0.0.0.0:32771->8080/tcp, 0.0.0.0:32770->8081/tcp, 0.0.0.0:32769->8140/tcp, 0.0.0.0:32768->8443/tcp   pe-lg.puppet.vm
    ```
2. Note the mapped port for 443, which in this case is 32773
3. Visit https://localhost:32773 in your browser
4. Accept security risk (self signed cert)
5. Login: admin/puppetlabs

### Logging into any of the containers
Ssh is running in all the containers so you can use ssh if you grab the mapped ssh port number. `ssh root@localhost -p 32774`

Login: root/test

You can also bypass ssh and run docker exec or docker-compose exec

1. cd spec/docker/extra-large
2. docker-compose exec pe_xl_core /bin/bash

**Note:** pe_xl_core is the name of the service defined in the respective docker-compose file.

This will run an interactive bash shell in the running container.

### Upgrades
There is also a upgrade.sh script that is similar to the provision.sh script.  This script will upgrade an already provisioned PE stack to the version specified in the update_params.json file.

### Other notes
1. The provision plan is not fully idempotent.
2. Some tasks may fail when run due to resource constraints.
3. You can rerun the provision.sh script on the same architecture without destroying the containers.  This can sometimes complete the provision process successfully. 
4. Rerunning the provision script may result in errors due to idempotency issues with tasks and plans.
5. Please remember you are starting the equilivent of 3-6 VMs on a single system.  
6. You can use top to view all the processes being run in the containers.
7. Docker will use the privilege mode option when running these examples (systemd support)
8. Systemd is running inside these containers!  The real systemd, not the fake one.
