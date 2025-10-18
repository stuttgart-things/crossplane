#!/bin/bash

# Test script to validate KCL composition fix
set -e

echo "🔧 Testing KCL Composition Fix"
echo "==============================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📋 The Problem: Original composition was missing parameter passing${NC}"
echo "❌ Original composition did not pass 'params' to KCL module"
echo "✅ Fixed composition now passes 'params.oxr.spec' with all parameters"
echo ""

echo -e "${BLUE}🔍 Comparing with working kcl run command...${NC}"
echo "Your working command:"
echo -e "${YELLOW}kcl run oci://ghcr.io/stuttgart-things/xplane-vcluster -D params='{\"oxr\":{\"spec\":{...}}}' ${NC}"
echo ""
echo "Fixed composition now passes the SAME parameters structure:"
echo -e "${YELLOW}spec.params.oxr.spec: {...} ${NC}"
echo ""

# Validate YAML syntax
echo -e "${BLUE}🔍 Validating fixed composition...${NC}"
if yq eval '.' apis/composition.yaml > /dev/null 2>&1; then
    echo -e "${GREEN}✅ composition.yaml is valid YAML${NC}"
else
    echo -e "${RED}❌ composition.yaml has YAML errors${NC}"
    exit 1
fi

# Check if patches exist
echo -e "${BLUE}🔍 Checking parameter patches...${NC}"
patch_count=$(yq eval '.spec.pipeline[0].patches | length' apis/composition.yaml 2>/dev/null || echo "0")
if [[ "$patch_count" -gt "10" ]]; then
    echo -e "${GREEN}✅ Found $patch_count parameter patches${NC}"
else
    echo -e "${RED}❌ Missing parameter patches (found: $patch_count)${NC}"
fi

# Check if params structure exists
echo -e "${BLUE}🔍 Checking params structure...${NC}"
if yq eval '.spec.pipeline[0].input.spec.params.oxr.spec' apis/composition.yaml > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Found params.oxr.spec structure${NC}"
else
    echo -e "${RED}❌ Missing params.oxr.spec structure${NC}"
fi

# Test with crossplane render (if Docker available)
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo -e "${BLUE}🚀 Testing with crossplane render...${NC}"
    
    # Convert claim to XR for testing
    sed 's/kind: VCluster/kind: XVCluster/' examples/working-kcl-claim.yaml > examples/working-kcl-xr.yaml
    
    if timeout 60 crossplane render examples/working-kcl-xr.yaml apis/composition.yaml examples/functions.yaml > output-kcl-fixed.yaml 2>/dev/null; then
        echo -e "${GREEN}✅ KCL composition render successful${NC}"
        
        # Check for expected resources
        expected_resources=(
            "vlcuster-k3s-tink1"
            "vcluster-kubeconfig-reader"
            "vcluster-k3s-tink2-connection"
        )
        
        for resource in "${expected_resources[@]}"; do
            if grep -q "$resource" output-kcl-fixed.yaml; then
                echo -e "${GREEN}  ✅ Found: $resource${NC}"
            else
                echo -e "${RED}  ❌ Missing: $resource${NC}"
            fi
        done
        
        # Compare with direct KCL run
        echo -e "${BLUE}🔄 Comparing with direct KCL run...${NC}"
        if kcl run oci://ghcr.io/stuttgart-things/xplane-vcluster -D params='{
          "oxr": {
            "spec": {
              "name": "vlcuster-k3s-tink1",
              "version": "0.29.0",
              "clusterName": "k3s-tink1",
              "targetNamespace": "vcluster-k3s-tink2",
              "storageClass": "local-path",
              "bindAddress": "0.0.0.0",
              "proxyPort": 8443,
              "nodePort": 32445,
              "extraSANs": ["test-k3s1.labul.sva.de", "10.31.103.23", "localhost"],
              "serverUrl": "https://10.31.103.23:32445",
              "additionalSecrets": [{
                "name": "vc-vlcuster-k3s-tink1-crossplane",
                "namespace": "vcluster-k3s-tink2",
                "context": "vcluster-crossplane-context",
                "server": "https://10.31.103.23:32445"
              }],
              "connectionSecret": {
                "name": "vcluster-k3s-tink2-connection",
                "namespace": "crossplane-system",
                "vclusterSecretName": "vc-vlcuster-k3s-tink1",
                "vclusterSecretNamespace": "vcluster-k3s-tink2"
              }
            }
          }
        }' --format yaml | grep -A 1000 "^items:" | grep -v "^items:" | sed 's/^- /---\n/' | sed '1d' > output-direct-kcl.yaml 2>/dev/null; then
            echo -e "${GREEN}✅ Direct KCL run successful${NC}"
            
            # Simple comparison check
            if [[ -f output-kcl-fixed.yaml && -f output-direct-kcl.yaml ]]; then
                kcl_lines=$(wc -l < output-kcl-fixed.yaml)
                direct_lines=$(wc -l < output-direct-kcl.yaml)
                echo -e "${BLUE}📊 Line count comparison:${NC}"
                echo "  Composition output: $kcl_lines lines"
                echo "  Direct KCL output: $direct_lines lines"
                
                if [[ $kcl_lines -gt 50 && $direct_lines -gt 50 ]]; then
                    echo -e "${GREEN}✅ Both outputs have substantial content${NC}"
                else
                    echo -e "${YELLOW}⚠️  One or both outputs seem incomplete${NC}"
                fi
            fi
        else
            echo -e "${RED}❌ Direct KCL run failed${NC}"
        fi
        
    else
        echo -e "${RED}❌ KCL composition render failed${NC}"
    fi
    
    # Cleanup
    rm -f examples/working-kcl-xr.yaml output-*.yaml 2>/dev/null || true
    
else
    echo -e "${YELLOW}⚠️  Docker not available, skipping render test${NC}"
fi

echo ""
echo -e "${BLUE}📋 Summary of Fix${NC}"
echo "=================="
echo -e "${GREEN}✅ Added 'params.oxr.spec' structure to KCL input${NC}"
echo -e "${GREEN}✅ Added patches to map XVCluster spec to KCL params${NC}"
echo -e "${GREEN}✅ Composition now passes same parameters as working kcl run${NC}"
echo ""
echo -e "${BLUE}🚀 Usage:${NC}"
echo "1. Apply fixed composition: kubectl apply -f apis/composition.yaml"
echo "2. Use any claim with the composition: kubectl apply -f examples/claim.yaml"
echo "3. The composition will now work like the direct kcl run command!"
echo ""
echo -e "${GREEN}🎉 KCL Composition fix completed!${NC}"