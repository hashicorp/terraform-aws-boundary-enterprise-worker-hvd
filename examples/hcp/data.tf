# Copyright IBM Corp. 2026
# SPDX-License-Identifier: MPL-2.0


#------------------------------------------------------------------------------
# HCP data sources
#------------------------------------------------------------------------------
data "hcp_boundary_cluster" "this" {
  count = var.hcp_boundary_cluster_name != "" && var.hcp_boundary_cluster_name != null ? 1 : 0

  cluster_id = var.hcp_boundary_cluster_name # The HCP API uses the variable "cluster_id" but this is actually the cluster name
  project_id = var.hcp_boundary_project_id   # This is the UUID of the HCP project where the Boundary cluster is running
}
