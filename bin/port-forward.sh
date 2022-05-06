#!/bin/bash
LEADER=$1
kubectl port-forward $LEADER 7687:7687 7474:7474
