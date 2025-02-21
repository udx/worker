#!/bin/bash

# Source test helpers
# shellcheck source=../test_helpers.sh disable=SC1091
source "/home/udx/tests/test_helpers.sh"

# Test SBOM commands
print_header "SBOM Tests"

# Test SBOM generation
print_info "Testing: sbom generate"
if ! worker sbom generate > /tmp/test-sbom.json; then
    print_error "sbom generate should create SBOM file"
    exit 1
fi

# Test SBOM verify
print_info "Testing: sbom verify"
if ! worker sbom verify; then
    print_error "sbom verify should check package integrity"
    exit 1
fi

# Test SBOM format options
print_info "Testing: sbom generate with format"
if ! worker sbom generate --format json > /tmp/test-sbom.json; then
    print_error "sbom generate with json format failed"
    exit 1
fi

# Test SBOM type options
print_info "Testing: sbom generate with type"
for type in system python all; do
    if ! worker sbom generate --type "$type" > "/tmp/test-sbom-$type.json"; then
        print_error "sbom generate for type $type failed"
        exit 1
    fi
    rm -f "/tmp/test-sbom-$type.json"
done

# Cleanup
rm -f /tmp/test-sbom.json

# All tests passed
print_success "All SBOM tests passed"
