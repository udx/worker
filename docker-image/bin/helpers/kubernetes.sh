# Description: Kubernetes module for kubectl commands

# Check if kubectl is installed
function k8s_check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "kubectl is not installed. Please install it first."
        return 1
    fi
}

k8s_application_list() {
    local namespace="${1:---all-namespaces}"
    kubectl get pods "$namespace"
}