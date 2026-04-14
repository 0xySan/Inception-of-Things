#!/bin/sh

sudo kubectl run nginx --image=nginx --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"artgirarsw"}}}'

