# Fast DSM

The Fast DSM is designed to quickly and easily create a Trend Micro Deep Security Manager and database for POC or demo purposes.  This script leverages Docker to a deploy the DSM manager and a Postgres database.

Please note that this is **NOT** intended to protect a persistent and environment and should only be used as a temporary setup and is not officially supported. 

## Getting Started

The Fast DSM will require that you launch and EC2 instance.  See the Prerequisties below for more details.

### Prerequisites

EC2 Instance Requirements

```
Red Hat Enterprise Linux 7 Operating System
Min of 2 CPU and 8 GB RAM
Min 30 GB of space in the root filesystem, 50 recommended
Instance will need access to the internet
Security groups: inbound access for 4118-4122 and 443
```

### Installing

* Copy the awsFastDsm.sh script into your EC2 instance and execute it as root. 
* Once it's finished installing, open your web browswer and go to the instance's IP address using https.
```
Default login is MasterAdmin and the Password is Password123!
```
* Please change your MasterAdmin password after install. 

## Running the DSM

At this point your DSM should be up and running.  In order to test it, you will need to add a license key under Administration > Licenses.  You can then activate computers and being testing the modules.


## More Info

If you need any additional information or want to learn more about the product, please visit our [Help Center.](http://help.deepsecurity.trendmicro.com/) 


