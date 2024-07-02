#!/bin/sh

# Function to cleanup actors
cleanup_actors() {
    echo "Cleaning up actors"
    
    # Example: Log out from Azure
    az logout
    
    # Example: Deactivate GCP service account
    gcloud auth revoke --all
}
