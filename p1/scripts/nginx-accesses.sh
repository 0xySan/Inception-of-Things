#!/bin/sh

sudo kubectl expose pod nginx --type=NodePort --port=80

