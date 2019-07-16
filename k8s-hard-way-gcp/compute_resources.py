import subprocess
import logging
import os

import pulumi
from pulumi_gcp import compute

#TODO Any class properties shall be readable as strings, it looks this feature is not ready for python
#BODY Issue: https://github.com/pulumi/pulumi/issues/2366
class ClusterConfig:
    public_address = None
    network = None
    subnet = None
    firewall_external = None
    firewall_internal = None
    instances = { "controllers": { }, "workers": { }}

    instance_ips = {}


    def execute(self, cmd, cwd=None, capture_output=False, env=None, raise_errors=True):
        """Execute an external command (wrapper for Python subprocess)."""
        logging.info('Executing command: {cmd}'.format(cmd=str(cmd)))
        stdout = subprocess.PIPE if capture_output else None
        process = subprocess.Popen(cmd, cwd=cwd, env=env, stdout=stdout)
        output = process.communicate()[0]
        returncode = process.returncode
        if returncode:
            # Error
            if raise_errors:
                raise subprocess.CalledProcessError(returncode, cmd)
            else:
                logging.info('Command returned error status %s', returncode)
        if output:
            logging.info(output)
        return returncode, output

    #TODO Dirty workaround to ready values from pulumi CLI or via export (no option to read it directly from Output object)
    #BODY Issue: https://github.com/pulumi/pulumi/issues/2366
    def fill_instances_ips(self):

        #FIXME works but throws also exception : raise TypeError('An asyncio.Future, a coroutine or an awaitable is 'TypeError: An asyncio.Future, a coroutine or an awaitable is required`
        #asyncio.gather(cc.instances['controllers'][0].network_interfaces.apply(lambda network_interfaces: print(network_interfaces[0])))
        #instances['controllers'][0].network_interfaces.apply(lambda network_interfaces: print(network_interfaces[0]['accessConfigs']['natIp']))
        
        #Read from pulumi CLI
        for instance_nbr in self.instances['controllers'].keys():
            self.instance_ips["controller-" + str(instance_nbr)] = \
                self.execute(['pulumi', 'stack', 'output', 'controller-' + str(instance_nbr)], None, True, os.environ)[1].decode().strip()

        for instance_nbr in self.instances['workers'].keys():
            self.instance_ips["worker-" + str(instance_nbr)] = \
                self.execute(['pulumi', 'stack', 'output', 'worker-' + str(instance_nbr)], None, True, os.environ)[1].decode().strip()


def create():

    cc = ClusterConfig()

    public_address = compute.address.Address("kubernetes-the-hard-way")
    cc.public_address = public_address

    network = compute.Network("kubernetes-the-hard-way", auto_create_subnetworks = False)
    subnet = compute.Subnetwork("kubernetes", network = network, ip_cidr_range = "10.240.0.0/24")
    cc.network = network
    cc.subnet = subnet

    firewall_external = compute.Firewall(
        "kubernetes-the-hard-way-allow-external",
        network=network.self_link,
        source_ranges = ["0.0.0.0/0"],
        allows=[
            {
                "protocol": "tcp",
                "ports": ["22", "6443"]
            },
            {
                "protocol": "icmp"
            }
        ]
    )

    firewall_internal = compute.Firewall(
        "kubernetes-the-hard-way-allow-internal",
        network=network.self_link,
        source_ranges = ["10.240.0.0/24", "10.200.0.0/16"],
        allows=[
            {
                "protocol": "tcp"
            },
            {
                "protocol": "icmp"
            },
            {
                "protocol": "udp"
            },
        ]
    )

    cc.firewall_external = firewall_external
    cc.firewall_internal = firewall_internal

    #Create controllers
    for i in range(0, 3):
        instance = compute.Instance(
            "controller-" + str(i),
            name="controller-" + str(i),
            machine_type="g1-small",
            #machine_type="n1-standard-1",
            boot_disk={
                "initializeParams": {
                    "size": 200,
                    "image": "ubuntu-os-cloud/ubuntu-1804-lts"
                }
            },
            can_ip_forward=True,
            network_interfaces=[{
                "network": network.id,
                "subnetwork": subnet.id,
                "network_ip": "10.240.0.1" + str(i),
                "accessConfigs": [{
                    #Assign External IP address to the instance
                    "network_tier": "STANDARD"
                 }]
            }],
            service_account={
                "scopes": [
                    "compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"
                ],
            },
            tags=[
                "kubernetes-the-hard-way", "controller"
            ]
        )

        cc.instances["controllers"][i] = instance

        #TODO if a resource is not created then one cannot call export on an unpopulated property/key since it will throw error
        #pulumi.export("controller-" + str(i), instance.network_interfaces[0]['accessConfigs'][0]['natIp'])

        #print("controller-" + str(i))
        #pulumi.export("print-controller-"+str(i), instance.name.apply(lambda name: print(name)))
        #pulumi.export("print-controller-"+str(i), cc.instances["controllers"][i].network_interfaces.apply(lambda network_interfaces: print(network_interfaces[0]['accessConfigs'][0]['natIp'])))

    #Create workers
    for i in range(0, 3):
        instance = compute.Instance(
            "worker-" + str(i),
            name="worker-" + str(i),
            machine_type="g1-small",
            #machine_type="n1-standard-1",
            boot_disk={
                "initializeParams": {
                    "size": 200,
                    "image": "ubuntu-os-cloud/ubuntu-1804-lts"
                }
            },
            can_ip_forward=True,
            network_interfaces=[{
                "network": network.id,
                "subnetwork": subnet.id,
                "network_ip": "10.240.0.2" + str(i),
                "accessConfigs": [{
                    #Assign External IP address to the instance
                    "network_tier": "STANDARD"
                 }]
            }],
            service_account={
                "scopes": [
                    "compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"
                ],
            },
            metadata={
                "pod-cidr": "10.200." + str(i) +".0/24"
            },
            tags=[
                "kubernetes-the-hard-way", "worker"
            ]
        )

        cc.instances["workers"][i] = instance
        
        #TODO if a resource is not created then one cannot call export on an unpopulated property/key since it will throw error
        #pulumi.export("worker-" + str(i), instance.network_interfaces[0]['accessConfigs'][0]['natIp'])
        
        #print("worker-" + str(i))
        #pulumi.export("print-worker-"+str(i), instance.name.apply(lambda name: print(name)))
        #pulumi.export("print-worker-"+str(i), cc.instances["workers"][i].network_interfaces.apply(lambda network_interfaces: print(network_interfaces[0]['accessConfigs'][0]['natIp'])))
    
    #Fill in ips when instance creation is done
    #cc.fill_instances_ips()

    return cc