# neo4j-google-k8s-marketplace

This repository contains instructions and files necessary for running Neo4j Enterprise via Google's
Hosted Kubernetes Marketplace.

# Getting started

## Updating git submodules

You can run the following commands to make sure submodules
are populated with proper code.

```shell
git submodule sync --recursive
git submodule update --recursive --init --force
```

# User Guide

## Overview

General application overview, covering basic functions and configuration options. This section
must also link to the published Cloud Launcher solution URL.

## One time Setup

- Configuring client tools
- Installing the Application CRD
- Acquiring and installing a license Secret from Cloud Launcher (if applicable)

## Installation

- Commands for installing the application
- Passing parameters available in UI configuration
- Pinning image references to immutable digests

## Basic Usage

- Connecting to an admin console (if applicable)
- Connecting a client tool and running a sample command (if acclipable)
- Modifying usernames and passwords
- Enabling ingress and installing TLS certs (if applicable)

## Backup and Restore

- Backing up application state
- Restoring application state from a backup

## Image Updates

Updating application images, assuming patch/minor updates

## Scaling

Scaling the application (if applicable)


