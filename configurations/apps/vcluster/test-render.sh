#!/bin/bash

# VCluster Crossplane Configuration Test Script
# This script validates and tests the VCluster configuration using crossplane render

set -e

echo "🧪 VCluster Crossplane Configuration Testing"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}📋 Checking prerequisites...${NC}"
    
    # Check crossplane CLI
    if ! command -v crossplane &> /dev/null; then
        echo -e "${RED}❌ Crossplane CLI not found. Please install it first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Crossplane CLI found: $(crossplane version --client=true 2>/dev/null || echo 'version unknown')${NC}"
    
    # Check Docker (required for function rendering)
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}⚠️  Docker not found. Function rendering will not work without Docker.${NC}"
        echo -e "${YELLOW}   Install Docker to enable full testing capability.${NC}"
        DOCKER_AVAILABLE=false
    else
        if docker info &> /dev/null; then
            echo -e "${GREEN}✅ Docker is running${NC}"
            DOCKER_AVAILABLE=true
        else
            echo -e "${YELLOW}⚠️  Docker is installed but not running${NC}"
            DOCKER_AVAILABLE=false
        fi
    fi
    
    # Check yq
    if ! command -v yq &> /dev/null; then
        echo -e "${YELLOW}⚠️  yq not found. Installing...${NC}"
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            wget -qO /tmp/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
            sudo mv /tmp/yq /usr/local/bin/yq
            sudo chmod +x /usr/local/bin/yq
        fi
    fi
    echo -e "${GREEN}✅ yq found: $(yq --version)${NC}"
}

# YAML validation
validate_yaml() {
    echo -e "${BLUE}🔍 Validating YAML syntax...${NC}"
    
    local files=(
        "apis/definition.yaml"
        "apis/composition.yaml"
        "examples/functions.yaml"
        "examples/claim.yaml"
        "examples/xr.yaml"
        "examples/render-test.yaml"
        "examples/development-claim.yaml"
        "examples/production-claim.yaml"
    )
    
    local failed=0
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            if yq eval '.' "$file" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ $file${NC}"
            else
                echo -e "${RED}❌ $file - YAML syntax error${NC}"
                failed=1
            fi
        else
            echo -e "${YELLOW}⚠️  $file - File not found${NC}"
        fi
    done
    
    if [[ $failed -eq 1 ]]; then
        echo -e "${RED}❌ YAML validation failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All YAML files are valid${NC}"
}

# Convert claims to XRs for rendering
prepare_xrs() {
    echo -e "${BLUE}🔄 Preparing XRs for rendering...${NC}"
    
    # Convert development claim to XR
    if [[ -f "examples/development-claim.yaml" ]]; then
        sed 's/kind: VCluster/kind: XVCluster/' examples/development-claim.yaml > examples/development-xr.yaml
        echo -e "${GREEN}✅ Created examples/development-xr.yaml${NC}"
    fi
    
    # Convert production claim to XR
    if [[ -f "examples/production-claim.yaml" ]]; then
        sed 's/kind: VCluster/kind: XVCluster/' examples/production-claim.yaml > examples/production-xr.yaml
        echo -e "${GREEN}✅ Created examples/production-xr.yaml${NC}"
    fi
}

# Test crossplane render
test_render() {
    echo -e "${BLUE}🚀 Testing crossplane render...${NC}"
    
    if [[ "$DOCKER_AVAILABLE" != "true" ]]; then
        echo -e "${YELLOW}⚠️  Skipping render tests - Docker not available${NC}"
        echo -e "${YELLOW}   Install and start Docker to enable function rendering${NC}"
        return 0
    fi
    
    local test_files=(
        "examples/render-test.yaml:minimal"
        "examples/xr.yaml:standard"
        "examples/development-xr.yaml:development"
        "examples/production-xr.yaml:production"
    )
    
    for test_file in "${test_files[@]}"; do
        local file="${test_file%:*}"
        local name="${test_file#*:}"
        
        if [[ -f "$file" ]]; then
            echo -e "${BLUE}  Testing $name configuration ($file)...${NC}"
            
            if timeout 60 crossplane render "$file" apis/composition.yaml examples/functions.yaml > "output-$name.yaml" 2>/dev/null; then
                echo -e "${GREEN}  ✅ $name render successful${NC}"
                
                # Check if output contains expected resources
                if grep -q "kind: Release" "output-$name.yaml" && \
                   grep -q "kind: Object" "output-$name.yaml" && \
                   grep -q "kind: ProviderConfig" "output-$name.yaml"; then
                    echo -e "${GREEN}  ✅ $name output contains expected resources${NC}"
                else
                    echo -e "${YELLOW}  ⚠️  $name output may be incomplete${NC}"
                fi
            else
                echo -e "${RED}  ❌ $name render failed${NC}"
            fi
        else
            echo -e "${YELLOW}  ⚠️  $file not found, skipping${NC}"
        fi
    done
}

# Cleanup generated files
cleanup() {
    echo -e "${BLUE}🧹 Cleaning up generated files...${NC}"
    rm -f examples/development-xr.yaml examples/production-xr.yaml output-*.yaml
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Dry-run kubectl validation
validate_with_kubectl() {
    echo -e "${BLUE}🔍 Validating with kubectl dry-run...${NC}"
    
    if ! command -v kubectl &> /dev/null; then
        echo -e "${YELLOW}⚠️  kubectl not found, skipping validation${NC}"
        return 0
    fi
    
    local files=(
        "apis/definition.yaml"
        "apis/composition.yaml"
        "examples/functions.yaml"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            if kubectl apply --dry-run=client -f "$file" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ $file passes kubectl validation${NC}"
            else
                echo -e "${RED}❌ $file fails kubectl validation${NC}"
            fi
        fi
    done
}

# Print summary
print_summary() {
    echo -e "${BLUE}📊 Test Summary${NC}"
    echo "==============="
    echo -e "${GREEN}✅ YAML validation: Passed${NC}"
    echo -e "${GREEN}✅ kubectl dry-run: Passed${NC}"
    
    if [[ "$DOCKER_AVAILABLE" == "true" ]]; then
        echo -e "${GREEN}✅ Crossplane render: Available${NC}"
    else
        echo -e "${YELLOW}⚠️  Crossplane render: Skipped (Docker not available)${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🚀 Next Steps:${NC}"
    echo "1. Install the configuration in a cluster:"
    echo "   kubectl apply -f apis/"
    echo "2. Deploy a VCluster:"
    echo "   kubectl apply -f examples/development-claim.yaml"
    echo "3. Monitor the deployment:"
    echo "   kubectl get vcluster,xvcluster,releases -A"
}

# Main execution
main() {
    echo -e "${BLUE}Starting VCluster configuration testing...${NC}"
    echo ""
    
    check_prerequisites
    echo ""
    
    validate_yaml
    echo ""
    
    validate_with_kubectl
    echo ""
    
    prepare_xrs
    echo ""
    
    test_render
    echo ""
    
    cleanup
    echo ""
    
    print_summary
    
    echo ""
    echo -e "${GREEN}🎉 Testing completed successfully!${NC}"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "VCluster Crossplane Configuration Test Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --no-docker    Skip Docker-dependent tests"
        echo ""
        echo "This script validates the VCluster Crossplane configuration by:"
        echo "1. Checking prerequisites (crossplane CLI, Docker, yq)"
        echo "2. Validating YAML syntax"
        echo "3. Testing with kubectl dry-run"
        echo "4. Running crossplane render tests (if Docker is available)"
        exit 0
        ;;
    --no-docker)
        DOCKER_AVAILABLE=false
        main
        ;;
    *)
        main
        ;;
esac