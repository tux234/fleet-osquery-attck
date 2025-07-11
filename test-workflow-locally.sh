#!/bin/bash

# Fleet Policy Automation - Local Testing Script
# This script mirrors the GitHub Actions workflow for local validation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Environment variables (matching workflow)
UPSTREAM_REPO='https://github.com/teoseller/osquery-attck.git'
COMMIT_TRACKING_FILE='.last_osquery_commit'
POLICIES_DIR='policies'
TECHNIQUES_DIR='policies/by-technique'

# Helper functions
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

cleanup() {
    print_step "Cleaning up temporary files..."
    rm -rf temp-osquery-attck temp_yml_files conf_files_list.txt 2>/dev/null || true
    print_success "Cleanup completed"
}

# Trap cleanup on exit
trap cleanup EXIT

main() {
    echo -e "${BLUE}Fleet Policy Automation - Local Testing${NC}"
    echo "========================================"
    echo
    
    # Step 1: Prerequisites validation
    print_step "Checking prerequisites..."
    
    # Check required tools
    for tool in git npm curl; do
        if command -v $tool >/dev/null 2>&1; then
            print_success "$tool is available"
        else
            print_error "$tool is not installed"
            exit 1
        fi
    done
    
    # Check Node.js version
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        print_success "Node.js version: $NODE_VERSION"
    else
        print_error "Node.js is not installed"
        exit 1
    fi
    
    echo
    
    # Step 2: Environment setup
    print_step "Setting up environment..."
    
    # Check if fleetctl is already installed
    print_step "Setting up Fleet CLI..."
    if command -v fleetctl >/dev/null 2>&1; then
        FLEETCTL_VERSION=$(fleetctl --version 2>/dev/null || echo "unknown")
        print_success "Fleet CLI already installed: $FLEETCTL_VERSION"
    else
        print_step "Installing Fleet CLI..."
        if npm install -g fleetctl >/dev/null 2>&1; then
            FLEETCTL_VERSION=$(fleetctl --version 2>/dev/null || echo "unknown")
            print_success "Fleet CLI installed: $FLEETCTL_VERSION"
        else
            print_error "Failed to install Fleet CLI"
            print_error "Please install Fleet CLI manually:"
            print_error "  npm install -g fleetctl"
            exit 1
        fi
    fi
    
    echo
    
    # Step 3: Clone upstream repository
    print_step "Cloning upstream repository..."
    
    if git clone $UPSTREAM_REPO temp-osquery-attck >/dev/null 2>&1; then
        cd temp-osquery-attck
        LATEST_COMMIT=$(git rev-parse HEAD)
        cd ..
        print_success "Upstream repository cloned"
        print_success "Latest commit: $LATEST_COMMIT"
    else
        print_error "Failed to clone upstream repository"
        exit 1
    fi
    
    echo
    
    # Step 4: Check for changes
    print_step "Checking for changes..."
    
    if [ -f "$COMMIT_TRACKING_FILE" ]; then
        STORED_COMMIT=$(cat $COMMIT_TRACKING_FILE)
        print_success "Stored commit: $STORED_COMMIT"
        
        if [ "$LATEST_COMMIT" != "$STORED_COMMIT" ]; then
            print_success "Changes detected - proceeding with conversion"
            HAS_CHANGES=true
        else
            print_warning "No changes detected"
            HAS_CHANGES=false
        fi
    else
        print_warning "No stored commit found - first run"
        HAS_CHANGES=true
    fi
    
    echo
    
    if [ "$HAS_CHANGES" = false ] && [ "$1" != "--force" ]; then
        print_warning "No changes detected. Use --force to process anyway."
        exit 0
    fi
    
    # Step 5: Process configuration files
    print_step "Processing configuration files..."
    
    # Find .conf files
    find temp-osquery-attck -name "*.conf" -type f > conf_files_list.txt
    CONF_COUNT=$(wc -l < conf_files_list.txt)
    
    if [ $CONF_COUNT -eq 0 ]; then
        print_error "No .conf files found"
        exit 1
    fi
    
    print_success "Found $CONF_COUNT .conf files"
    
    # Create temporary directory for converted files
    mkdir -p temp_yml_files
    
    echo
    print_step "Converting .conf files to Fleet YAML..."
    
    # Convert files
    SUCCESS_COUNT=0
    FAIL_COUNT=0
    
    while IFS= read -r conf_file; do
        filename=$(basename "$conf_file" .conf)
        printf "  Processing: %-40s " "$filename"
        
        if fleetctl convert -f "$conf_file" > "temp_yml_files/${filename}.yml" 2>/dev/null; then
            if [ -s "temp_yml_files/${filename}.yml" ]; then
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                echo -e "${GREEN}✓${NC}"
            else
                rm -f "temp_yml_files/${filename}.yml"
                FAIL_COUNT=$((FAIL_COUNT + 1))
                echo -e "${RED}✗ (empty)${NC}"
            fi
        else
            FAIL_COUNT=$((FAIL_COUNT + 1))
            echo -e "${RED}✗ (failed)${NC}"
        fi
    done < conf_files_list.txt
    
    echo
    print_success "Conversion completed: $SUCCESS_COUNT successful, $FAIL_COUNT failed"
    
    if [ $SUCCESS_COUNT -eq 0 ]; then
        print_error "No successful conversions"
        exit 1
    fi
    
    echo
    
    # Step 5.5: Improve query names and platform targeting
    print_step "Improving query names and platform targeting..."
    
    # Install yq if not available
    YQ_AVAILABLE=true
    if ! command -v yq >/dev/null 2>&1; then
        print_warning "yq not found, trying to install..."
        if command -v brew >/dev/null 2>&1; then
            if ! brew install yq >/dev/null 2>&1; then
                print_warning "Failed to install yq, will use fallback method"
                YQ_AVAILABLE=false
            fi
        else
            print_warning "yq not available and brew not found, will use fallback method"
            YQ_AVAILABLE=false
        fi
    fi
    
    # Process each converted YAML file to improve names and platforms
    for yml_file in temp_yml_files/*.yml; do
        if [ -f "$yml_file" ]; then
            filename=$(basename "$yml_file" .yml)
            printf "  Improving: %-40s " "$filename"
            
            # Determine platform based on filename
            platform=""
            if [[ "$filename" =~ ^linux ]] || [[ "$filename" =~ generic ]]; then
                platform="linux"
            elif [[ "$filename" =~ ^windows ]]; then
                platform="windows"
            else
                platform=""
            fi
            
            if [ "$YQ_AVAILABLE" = true ]; then
                # Use yq to improve query names and set platform
                temp_improved="${yml_file}.improved"
                yq_exit_code=0
                
                if [ -n "$platform" ]; then
                    yq eval-all '
                        select(.kind == "query") |
                        .spec.name = ("MITRE - " + ((.spec.description // "") | split(" - ATT&CK")[0] | split(" - ATTACK")[0])) |
                        .spec.platform = "'"$platform"'"
                    ' "$yml_file" > "$temp_improved" 2>/dev/null || yq_exit_code=$?
                else
                    yq eval-all '
                        select(.kind == "query") |
                        .spec.name = ("MITRE - " + ((.spec.description // "") | split(" - ATT&CK")[0] | split(" - ATTACK")[0]))
                    ' "$yml_file" > "$temp_improved" 2>/dev/null || yq_exit_code=$?
                fi
                
                if [ $yq_exit_code -eq 0 ] && [ -s "$temp_improved" ] && grep -q "kind: query" "$temp_improved"; then
                    mv "$temp_improved" "$yml_file"
                    echo -e "${GREEN}✓${NC}"
                else
                    rm -f "$temp_improved"
                    if [ -n "$platform" ]; then
                        sed -i.bak "s/^  platform: .*/  platform: $platform/" "$yml_file" 2>/dev/null
                        rm -f "${yml_file}.bak"
                    fi
                    echo -e "${YELLOW}~${NC}"
                fi
            else
                # Fallback: only set platform when yq is unavailable
                if [ -n "$platform" ]; then
                    sed -i.bak "s/^  platform: .*/  platform: $platform/" "$yml_file" 2>/dev/null
                    rm -f "${yml_file}.bak"
                fi
                echo -e "${YELLOW}~${NC}"
            fi
        fi
    done
    
    print_success "Query improvement completed"
    
    echo
    
    # Step 6: Generate policy files
    print_step "Generating policy files..."
    
    # Create directories
    mkdir -p $POLICIES_DIR $TECHNIQUES_DIR
    
    # Generate complete policy file combining all individual files
    > $POLICIES_DIR/mitre-attck-complete.yml
    
    FIRST_FILE=true
    for yml_file in temp_yml_files/*.yml; do
        if [ -f "$yml_file" ]; then
            if [ "$FIRST_FILE" = true ]; then
                FIRST_FILE=false
                cat "$yml_file" >> $POLICIES_DIR/mitre-attck-complete.yml
            else
                echo "---" >> $POLICIES_DIR/mitre-attck-complete.yml
                tail -n +2 "$yml_file" >> $POLICIES_DIR/mitre-attck-complete.yml
            fi
        fi
    done
    
    print_success "Generated complete policy file"
    
    # Create individual technique files
    INDIVIDUAL_COUNT=0
    for yml_file in temp_yml_files/*.yml; do
        if [ -f "$yml_file" ]; then
            filename=$(basename "$yml_file" .yml)
            cp "$yml_file" "$TECHNIQUES_DIR/${filename}.yml"
            INDIVIDUAL_COUNT=$((INDIVIDUAL_COUNT + 1))
        fi
    done
    
    print_success "Generated $INDIVIDUAL_COUNT individual technique files"
    
    echo
    
    # Step 6.5: Validate generated policies
    print_step "Validating generated policies..."
    
    VALIDATION_ERRORS=0
    
    # Check if complete policy file exists and has content
    if [ ! -f "$POLICIES_DIR/mitre-attck-complete.yml" ] || [ ! -s "$POLICIES_DIR/mitre-attck-complete.yml" ]; then
        print_error "Complete policy file is missing or empty"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    else
        print_success "Complete policy file exists and has content"
    fi
    
    # Validate file structure
    if ! grep -q "^---" "$POLICIES_DIR/mitre-attck-complete.yml"; then
        print_error "Complete policy file missing YAML document separators"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    else
        print_success "Complete policy file has proper YAML structure"
    fi
    
    # Check individual technique files
    TECHNIQUE_COUNT_VALIDATION=$(find "$TECHNIQUES_DIR" -name "*.yml" 2>/dev/null | wc -l)
    if [ $TECHNIQUE_COUNT_VALIDATION -eq 0 ]; then
        print_error "No individual technique files generated"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    else
        print_success "Generated $TECHNIQUE_COUNT_VALIDATION individual technique files"
        
        # Validate individual files have proper YAML structure
        INVALID_INDIVIDUAL=0
        for yml_file in "$TECHNIQUES_DIR"/*.yml; do
            if [ -f "$yml_file" ]; then
                if ! grep -q "^---" "$yml_file" || ! grep -q "^kind: query" "$yml_file"; then
                    print_error "Invalid YAML structure in $(basename "$yml_file")"
                    INVALID_INDIVIDUAL=$((INVALID_INDIVIDUAL + 1))
                fi
            fi
        done
        
        if [ $INVALID_INDIVIDUAL -eq 0 ]; then
            print_success "All individual files have proper YAML structure"
        else
            print_error "$INVALID_INDIVIDUAL files have invalid structure"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
    fi
    
    # Validate Fleet query structure
    print_step "Running Fleet query structure validation..."
    
    # Count Fleet query documents
    VALID_QUERIES=$(grep -c "^kind: query" "$POLICIES_DIR/mitre-attck-complete.yml" 2>/dev/null || echo "0")
    API_VERSIONS=$(grep -c "^apiVersion: v1" "$POLICIES_DIR/mitre-attck-complete.yml" 2>/dev/null || echo "0")
    SPEC_SECTIONS=$(grep -c "^spec:" "$POLICIES_DIR/mitre-attck-complete.yml" 2>/dev/null || echo "0")
    
    # Check for YAML syntax errors
    if grep -q "^[[:space:]]*-[[:space:]]*$" "$POLICIES_DIR/mitre-attck-complete.yml"; then
        print_error "Found malformed YAML list items"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    elif [ "$VALID_QUERIES" -eq 0 ]; then
        print_error "No Fleet queries found in policy file"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    elif [ "$VALID_QUERIES" != "$API_VERSIONS" ] || [ "$VALID_QUERIES" != "$SPEC_SECTIONS" ]; then
        print_error "Inconsistent Fleet query structure (queries: $VALID_QUERIES, apiVersions: $API_VERSIONS, specs: $SPEC_SECTIONS)"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    else
        print_success "Fleet query structure validation passed ($VALID_QUERIES queries found)"
        print_warning "Note: fleetctl dry-run only supports config/team specs, not query specs"
    fi
    
    # File size validation
    COMPLETE_SIZE=$(wc -c < "$POLICIES_DIR/mitre-attck-complete.yml")
    if [ $COMPLETE_SIZE -lt 1000 ]; then
        print_error "Complete policy file suspiciously small ($COMPLETE_SIZE bytes)"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    else
        print_success "Complete policy file has reasonable size ($COMPLETE_SIZE bytes)"
    fi
    
    # Validation summary
    echo
    print_step "Validation Summary:"
    echo "- Validation errors: $VALIDATION_ERRORS"
    echo "- Complete policy size: $COMPLETE_SIZE bytes"
    echo "- Individual technique files: $TECHNIQUE_COUNT_VALIDATION"
    
    if [ $VALIDATION_ERRORS -gt 0 ]; then
        print_error "Validation failed with $VALIDATION_ERRORS errors"
        echo
        print_warning "Files were generated but failed validation checks"
        print_warning "Review the errors above before deploying policies"
        echo
    else
        print_success "All validations passed successfully"
        echo
    fi
    
    echo
    
    # Step 7: Generate documentation
    print_step "Generating documentation..."
    
    cat > README.md << 'EOF'
# Fleet MITRE ATT&CK Detection Policies

This repository contains automatically generated Fleet policies based on the MITRE ATT&CK framework, converted from osquery configurations provided by the [teoseller/osquery-attck](https://github.com/teoseller/osquery-attck) project.

## Quick Start

### Deploy All Policies
```bash
# Download and apply all MITRE ATT&CK policies
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/policies/mitre-attck/mitre-attck-complete.yml
fleetctl apply -f mitre-attck-complete.yml
```

### Deploy Individual Techniques
```bash
# Apply specific techniques
fleetctl apply -f policies/mitre-attck/by-technique/T1003-credential-dumping.yml
```

### Validate Before Applying
```bash
# Test configuration before applying
fleetctl apply --dry-run -f mitre-attck-complete.yml
```

## Repository Structure

```
policies/
└── mitre-attck/
    ├── mitre-attck-complete.yml    # All policies combined
    └── by-technique/               # Individual technique files
        ├── T1003-credential-dumping.yml
        ├── T1055-process-injection.yml
        └── ...
```

## Policy Information

- **Total Policies**: __POLICY_COUNT__ successfully converted
- **Last Updated**: __GENERATION_TIME__
- **Source Commit**: __SOURCE_COMMIT__
- **Update Schedule**: Weekly (Mondays at 2 AM UTC)

## Usage Notes

- All policies are automatically generated from upstream osquery configurations
- Policies are updated weekly when changes are detected in the source repository
- Each policy file includes metadata about its source and generation time
- Use `fleetctl apply --dry-run` to validate policies before deployment

## Requirements

- Fleet server with appropriate permissions
- fleetctl CLI tool installed
- Network access to download policy files

## Support

For issues with the policies themselves, please refer to the upstream [osquery-attck](https://github.com/teoseller/osquery-attck) repository.

For Fleet-specific questions, consult the [Fleet documentation](https://fleetdm.com/docs).
EOF
    
    # Replace placeholders with actual values
    sed -i.bak "s/__POLICY_COUNT__/$SUCCESS_COUNT/g" README.md
    sed -i.bak "s/__GENERATION_TIME__/$(date -u +"%Y-%m-%d %H:%M:%S UTC")/g" README.md
    sed -i.bak "s/__SOURCE_COMMIT__/$LATEST_COMMIT/g" README.md
    rm -f README.md.bak
    
    print_success "Documentation generated"
    
    echo
    
    # Step 8: Update commit tracking
    print_step "Updating commit tracking..."
    echo "$LATEST_COMMIT" > $COMMIT_TRACKING_FILE
    print_success "Commit tracking updated"
    
    echo
    
    # Step 9: Validation
    print_step "Validating generated files..."
    
    # Check if files exist and have content
    if [ -f "$POLICIES_DIR/mitre-attck-complete.yml" ] && [ -s "$POLICIES_DIR/mitre-attck-complete.yml" ]; then
        print_success "Complete policy file generated successfully"
    else
        print_error "Complete policy file is missing or empty"
    fi
    
    if [ -f "README.md" ] && [ -s "README.md" ]; then
        print_success "README.md generated successfully"
    else
        print_error "README.md is missing or empty"
    fi
    
    TECHNIQUE_FILES=$(find $TECHNIQUES_DIR -name "*.yml" 2>/dev/null | wc -l)
    if [ $TECHNIQUE_FILES -gt 0 ]; then
        print_success "$TECHNIQUE_FILES individual technique files generated"
    else
        print_error "No individual technique files generated"
    fi
    
    echo
    
    # Summary
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Local Testing Summary${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo "Source Commit: $LATEST_COMMIT"
    echo "Successful Conversions: $SUCCESS_COUNT"
    echo "Failed Conversions: $FAIL_COUNT"
    echo "Individual Files: $INDIVIDUAL_COUNT"
    echo "Validation Errors: $VALIDATION_ERRORS"
    echo "Complete Policy Size: $COMPLETE_SIZE bytes"
    echo "Generation Time: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo
    
    print_step "Next steps:"
    if [ $VALIDATION_ERRORS -eq 0 ]; then
        echo "1. ✅ All validations passed - files are ready for deployment"
        echo "2. Review generated files in $POLICIES_DIR/"
        echo "3. Commit changes: git add . && git commit -m 'Update Fleet policies'"
        echo "4. Push to GitHub to trigger workflow"
        echo "5. Deploy with: fleetctl apply -f $POLICIES_DIR/mitre-attck-complete.yml"
        
        print_success "Local testing completed successfully!"
    else
        echo "1. ❌ Validation failed - review errors above"
        echo "2. Fix validation issues before proceeding"
        echo "3. Re-run this script to validate fixes"
        echo "4. Only commit after all validations pass"
        
        print_warning "Local testing completed with validation errors!"
        exit 1
    fi
}

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Fleet Policy Automation - Local Testing Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --force    Force processing even if no changes detected"
    echo "  --help     Show this help message"
    echo
    echo "This script mirrors the GitHub Actions workflow for local validation."
    echo "It downloads osquery configurations and converts them to Fleet policies."
    exit 0
fi

# Run main function
main "$@"