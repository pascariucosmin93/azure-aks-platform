# Architecture Notes

## Goal

Provide a clean Terraform structure for an Azure AKS platform that can scale beyond a single cluster deployment.

## Principles

- keep modules small and composable
- separate networking from workload platform concerns
- avoid embedding secrets or environment-specific values in module code
- keep the public repository cloud-account agnostic

## Current Scope

This repository currently includes:

- hub-spoke network shape
- AKS cluster
- ACR
- Key Vault
- Log Analytics
- managed identity
- partial remote-state configuration for Azure Blob Storage

## Expected Extensions

- private DNS zones
- private AKS API server
- Application Gateway or Front Door integration
- workload identity and federated credentials
- policy assignments
- diagnostics settings and dashboards

## Terraform State

The environment compositions are prepared for an `azurerm` backend, but the live backend values are intentionally not committed.

Recommended pattern:

- store Terraform state in a dedicated Azure Storage Account
- keep one Blob container for Terraform state
- use a separate state key per environment
- manage backend access with Azure RBAC and least privilege
