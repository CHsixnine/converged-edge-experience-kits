```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2019 Intel Corporation.
```

# OpenNESS Container Kits repo

# Purpose
Repository contains set of Ansible playbooks for easy setup of OpenNESS in Network Edge and On-Premise modes.

# Preconditions
In order to use the playbooks several preconditions must be fulfilled:

* Hosts for Kubernetes master and workers (Edge Nodes) must have set proper and unique hostname (not `localhost`). That hostname must be in `/etc/hosts` as well. (refer to [Setup static hostname](#Setup-static-hostname))
* Inventory must be configured (refer to [Configuring inventory](#configuring-inventory)) 
* SSH keys must be exchanged with hosts (refer to [Exchanging SSH keys with hosts](#Exchanging-SSH-keys-with-hosts))
* Proxy must be configured if needed (refer to [Setting proxy](#setting-proxy))
* If a private repository is used Github token has to be set up (refer to [GitHub Token](#github-token))

# Running playbooks

For convenience, playbooks can be played by running helper deploy scripts.
Convention for the scripts is: `action_mode[_group].sh`. Following scripts are available:
* Network Edge mode
  * `deploy_ne.sh` - sets up cluster (first controller, then nodes)
  * `cleanup_ne.sh`
  * `deploy_ne_controller.sh`
  * `deploy_ne_node.sh`
* On Premise mode
  * `deploy_onprem_controller.sh`
  * `deploy_onprem_node.sh`

NOTE: Playbooks for Controller/Kubernetes master must be played before playbooks for Edge Nodes.

## Cleanup playbooks
Role of cleanup playbook is to revert changes made by deploy playbooks.
Teardown is made by going step by step in reverse order and undo the steps.

For example, when installing Docker - RPM repository is added and Docker installed, when cleaning up - Docker is uninstalled and then repository is removed.

Note that there might be some leftovers created by installed software.

## On Premise
`onprem_controller.yml`, `onprem_node.yml` contain playbooks for On Premise mode. Playbooks can be customized by (un)commenting roles that are optional and by customizing variables where needed.

## Network Edge
`ne_controller.yml`, `ne_node.yml` and `ne_cleanup.yml` contain playbooks for Network Edge mode.
Playbooks can be customized by (un)commenting roles that are optional and by customizing variables where needed.

### Kubernetes Topology Manager and CPU Management
In order to enable Topology Manager, customize `roles/kubernetes/worker/defaults/main.yml` file and change following variables:
* `cpu.policy` - to none (disabled) or static
* `cpu.reserved_cpus`
* `topology_manager.policy` - to none (default, disabled), best-effort, restricted, single-numa-node.

For more information regarding those features refer to [Kubernetes - Control Topology Management Policies on a node](https://kubernetes.io/docs/tasks/administer-cluster/topology-manager/) and
[Kubernetes - Control CPU Management Policies on the Node](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/).

### SRIOV
To customize SRIOV, edit `roles/sriov/common/defaults/main.yml` file and customize following variables:
* `fpga_sriov_userspace.enabled`
* `fpga_userspace_vf.enabled`
* `fpga_userspace_vf.vf_number`

# Q&A
## Setup static hostname
In order to set some custom static hostname a command can be used:
```
hostnamectl set-hostname kubeovn-master
```
Make sure if static hostname provided is proper and unique (refer to [K8s naming restrictions](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names))
The hostname provided nedds to be defined in /etc/hosts as well:
```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 kubeovn-master
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6 kubeovn-master
```

## Configuring inventory
In order to execute playbooks, `inventory.ini` must be configure to include specific hosts to run the playbooks on.

OpenNESS' inventory contains three groups: `all`, `edgenode_group`, and `controller_group`:
* `all` contains all the hosts (with configuration) used in any playbook
* `controller_group` contains host to be set up as a Kubernetes master / OpenNESS Edge Controller \
**WARNING: Since only one Controller is supported, `controller_group` can contain only 1 host.**
* `edgenode_group` contains hosts to be set up as a Kubernetes workers / OpenNESS Edge Nodes. \
**NOTE: All nodes will be joined to the master specified in `controller_group`.**

In `all` group you can specify all of your hosts for usage in other groups.
Example `all` group looks like:

```
[all]
ctrl ansible_ssh_user=root ansible_host=192.168.0.2
node1 ansible_ssh_user=root ansible_host=192.168.0.3
node2 ansible_ssh_user=root ansible_host=192.168.0.4
```

Then you can use those hosts in `edgenode_group` and `controller_group`, i.e.:
```
[edgenode_group]
node1
node2

[controller_group]
ctrl
```

## Exchanging SSH keys with hosts
Exchanging SSH keys will allow for password-less SSH from host running Ansible to hosts being set up.

First, host running Ansible must have generated SSH key. SSH key can be generated by executing `ssh-keygen` and following program's output. Here's example - key is located in standard location (`/root/.ssh/id_rsa`) and empty passphrase is used.
```
# ssh-keygen

Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):  <ENTER>
Enter passphrase (empty for no passphrase):  <ENTER>
Enter same passphrase again:  <ENTER>
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:vlcKVU8Tj8nxdDXTW6AHdAgqaM/35s2doon76uYpNA0 root@host
The key's randomart image is:
+---[RSA 2048]----+
|          .oo.==*|
|     .   .  o=oB*|
|    o . .  ..o=.=|
|   . oE.  .  ... |
|      ooS.       |
|      ooo.  .    |
|     . ...oo     |
|      . .*o+.. . |
|       =O==.o.o  |
+----[SHA256]-----+
```

Then, generated key must be copied to **every host from the inventory**. It is done by running `ssh-copy-id`, e.g.:
```
# ssh-copy-id root@host

/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_rsa.pub"
The authenticity of host '<IP> (<IP>)' can't be established.
ECDSA key fingerprint is SHA256:c7EroVdl44CaLH/IOCBu0K0/MHl8ME5ROMV0AGzs8mY.
ECDSA key fingerprint is MD5:38:c8:03:d6:5a:8e:f7:7d:bd:37:a0:f1:08:15:28:bb.
Are you sure you want to continue connecting (yes/no)? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
root@host's password:

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@host'"
and check to make sure that only the key(s) you wanted were added.
```

To make sure key is copied successfully, try to SSH to the host: `ssh 'root@host'`. It should not ask for the password.

## Setting proxy
If proxy is required in order to connect to the Internet it can be configured in `group_vars/all.yml` file.
Just provide values for `proxy_` variables and set `proxy_os_enable` to `true`.
Also append your network CIDR (e.g. `192.168.0.1/24`) to the `proxy_os_noproxy`.

Settings can look like this:

```
proxy_yum_url: "http://proxy.example.com:3128/"

proxy_os_enable: true
proxy_os_remove_old: true
proxy_os_http: "http://proxy.example.com:3128"
proxy_os_https: "http://proxy.example.com:3128"
proxy_os_ftp: "http://proxy.example.com:3128"
proxy_os_noproxy: "localhost,127.0.0.1,10.244.0.0/24,10.96.0.0/12,192.168.0.1/24"
```

## Setting Git
### GitHub Token
> NOTE: Only required when cloning private repositories. Not needed when using github.com/open-ness repositories.

In order to clone private repositories GitHub token must be provided.

To generate GitHub token refer to [GitHub help - Creating a personal access token for the command line](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).

To provide the token, edit value of `git_repo_token` variable in in `group_vars/all.yml`.

### Customize tag/commit/sha to checkout

Specific tag, commit or sha can be checked out by setting `git_repo_branch` variable in `group_vars/edgenode_group.yml` for Edge Nodes and `groups_vars/controller_group.yml` for Kubernetes master / Edge Controller.
