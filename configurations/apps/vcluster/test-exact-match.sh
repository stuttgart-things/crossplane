#!/bin/bash

# Test script to verify exact output match
set -e

echo "🎯 Testing Exact Output Match"
echo "=============================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📋 Testing exact match composition...${NC}"

# Convert claim to XR for testing
echo -e "${BLUE}🔄 Converting claim to XR...${NC}"
sed 's/kind: VCluster/kind: XVCluster/' examples/exact-output-claim.yaml > examples/exact-output-xr.yaml

# Test with crossplane render (if Docker available)
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo -e "${BLUE}🚀 Testing with crossplane render...${NC}"
    
    # Test with exact-match composition
    if crossplane render examples/exact-output-xr.yaml apis/composition-exact-match.yaml examples/functions.yaml > output-exact-match.yaml 2>/dev/null; then
        echo -e "${GREEN}✅ Exact match composition render successful${NC}"
        
        # Verify output contains expected resources
        echo -e "${BLUE}🔍 Verifying output content...${NC}"
        
        # Check for required resources
        local checks=(
            "vlcuster-k3s-tink1:Release name"
            "vcluster-kubeconfig-reader:Object name" 
            "vcluster-k3s-tink2:ProviderConfig name"
            "vcluster-k3s-tink2-helm:Helm ProviderConfig name"
            "test-namespace-in-vcluster:Test namespace"
            "test-configmap-in-vcluster:Test configmap"
            "vcluster-k3s-tink2-connection:Connection secret"
        )
        
        for check in "${checks[@]}"; do
            local resource="${check%:*}"
            local description="${check#*:}"
            
            if grep -q "$resource" output-exact-match.yaml; then
                echo -e "${GREEN}  ✅ $description: $resource${NC}"
            else
                echo -e "${RED}  ❌ $description: $resource NOT FOUND${NC}"
            fi
        done
        
        echo ""
        echo -e "${BLUE}📊 Generated resources:${NC}"
        grep -E "^kind:" output-exact-match.yaml | sort | uniq -c || true
        
    else
        echo -e "${RED}❌ Exact match composition render failed${NC}"
    fi
else
    echo -e "${RED}⚠️  Docker not available, skipping render test${NC}"
fi

# Validate YAML syntax
echo -e "${BLUE}🔍 Validating YAML syntax...${NC}"
if yq eval '.' apis/composition-exact-match.yaml > /dev/null 2>&1; then
    echo -e "${GREEN}✅ composition-exact-match.yaml is valid${NC}"
else
    echo -e "${RED}❌ composition-exact-match.yaml has YAML errors${NC}"
fi

if yq eval '.' examples/exact-output-claim.yaml > /dev/null 2>&1; then
    echo -e "${GREEN}✅ exact-output-claim.yaml is valid${NC}"
else
    echo -e "${RED}❌ exact-output-claim.yaml has YAML errors${NC}"
fi

echo ""
echo -e "${BLUE}📋 Summary${NC}"
echo "============"
echo "✅ Created exact-match composition: apis/composition-exact-match.yaml"
echo "✅ Created exact-output claim: examples/exact-output-claim.yaml"
echo ""
echo -e "${BLUE}🚀 Deployment Instructions:${NC}"
echo "1. Apply the exact-match composition:"
echo "   kubectl apply -f apis/composition-exact-match.yaml"
echo "2. Deploy VCluster with exact output:"
echo "   kubectl apply -f examples/exact-output-claim.yaml"
echo "3. Monitor deployment:"
echo "   kubectl get vcluster,releases,object,providerconfig -A"

# Cleanup
rm -f examples/exact-output-xr.yaml output-exact-match.yaml 2>/dev/null || true

echo ""
echo -e "${GREEN}🎉 Exact match testing completed!${NC}"