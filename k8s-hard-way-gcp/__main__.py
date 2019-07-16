#TODO Add parametrized options to cluster creation, file transfers accounted for
#BODY Parameters to be added: controller node count, worker node count, ip addressing for networking (transport and pod addressing), script for creating appropriate number of worker node json configs for cfssl

import pulumi

import compute_resources as cr


def main():
  #Cluster Config object
  cc = cr.create()

if __name__== "__main__":
  main()