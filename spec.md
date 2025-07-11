# Fleet Policy Automation - Developer Implementation Specification

## Project Overview

### Purpose
Automate the conversion of MITRE ATT&CK osquery configurations from the `teoseller/osquery-attck` repository into Fleet-compatible YAML policies. This system provides customers with ready-to-deploy threat detection policies that are automatically synchronized with upstream changes.

### Goals
- **Automation**: Weekly synchronization without manual intervention
- **Usability**: Provide both complete and granular deployment options
- **Reliability**: Robust error handling and validation
- **Security**: Follow GitHub Actions security best practices
- **Transparency**: Clear documentation and change tracking

---

## System Architecture

### High-Level Flow
```
Weekly Schedule → Check Upstream Changes → Convert .conf Files → Generate Policy Files → Commit & Release
```

### Components
1. **GitHub Actions Workflow** - Main automation engine
2. **Fleet CLI (fleetctl)** - Conversion tool for .conf to YAML
3. **Repository Structure** - Organized output for customer consumption
4. **Documentation System** - Auto-generated README and release notes
5. **Change Tracking** - Commit-based synchronization detection

### Repository Structure
```
fleet-detection-policies/
├── .github/workflows/
│   └── update-mitre-fleet-policies.yml    # Main automation workflow
├── policies/
│   └── mitre-attck/
│       ├── mitre-attck-complete.yml       # All policies combined
│       └── by-technique/                  # Individual technique files
│           ├── T1003-credential-dumping.yml
│           ├── T1055-process-injection.yml
│           └── ...
├── README.md                              # Auto-generated documentation
├── .last_osquery_commit                   # Tracks upstream state
└── test-workflow-locally.sh              # Local testing script
```

---

## Technical Requirements

### Dependencies
- **GitHub Actions Environment**: ubuntu-24.04 runner
- **Node.js**: Version 20 (LTS) for fleetctl installation
- **Fleet CLI**: Latest version via npm (`npm install -g fleetctl`)
- **Git**: For repository operations and change detection

### Upstream Source
- **Repository**: `https://github.com/teoseller/osquery-attck.git`
- **File Pattern**: `**/*.conf` (recursive search)
- **Change Detection**: Git commit SHA comparison

### Output Requirements
- **Complete Policy File**: Single YAML with all techniques
- **Individual Files**: One file per MITRE technique
- **Documentation**: Auto-generated README with usage instructions
- **Headers**: Detailed metadata in each generated file

---

## Workflow Implementation Details

### Trigger Configuration
```yaml
on:
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Mondays at 2 AM UTC
  workflow_dispatch:      # Manual trigger option
    inputs:
      force_update:
        description: 'Force update even if no changes detected'
        type: boolean
```

### Security Configuration
```yaml
permissions:
  contents: write    # Repository operations
  actions: read      # Workflow metadata
  metadata: read     # Repository metadata
```

### Environment Variables
```yaml
env:
  UPSTREAM_REPO: 'https://github.com/teoseller/osquery-attck.git'
  COMMIT_TRACKING_FILE: '.last_osquery_commit'
  POLICIES_DIR: 'policies/mitre-attck'
  TECHNIQUES_DIR: 'policies/mitre-attck/by-technique'
```

### Action Version Pinning (Security Best Practice)
- `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683` # v4.2.2
- `actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af` # v4.1.0
- `softprops/action-gh-release@01570a1f39cb168c169c802c3bceb9e93fb10974` # v2.2.0

---

## Data Processing Pipeline

### Step 1: Change Detection
```bash
# Clone upstream repository
git clone $UPSTREAM_REPO temp-osquery-attck

# Compare commit hashes
LATEST_COMMIT=$(git rev-parse HEAD)
STORED_COMMIT=$(cat .last_osquery_commit)

# Determine if processing needed
if [ "$LATEST_COMMIT" != "$STORED_COMMIT" ]; then
    HAS_CHANGES=true
fi
```

### Step 2: File Discovery
```bash
# Find all .conf files recursively
find temp-osquery-attck -name "*.conf" -type f > conf_files_list.txt

# Validate file count
CONF_COUNT=$(wc -l < conf_files_list.txt)
if [ $CONF_COUNT -eq 0 ]; then
    echo "Error: No .conf files found"
    exit 1
fi
```

### Step 3: Conversion Process
```bash
SUCCESS_COUNT=0
FAIL_COUNT=0

while IFS= read -r conf_file; do
    filename=$(basename "$conf_file" .conf)
    
    if fleetctl convert -f "$conf_file" > "temp_yml_files/${filename}.yml" 2>/dev/null; then
        if [ -s "temp_yml_files/${filename}.yml" ]; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            rm -f "temp_yml_files/${filename}.yml"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done < conf_files_list.txt
```

### Step 4: File Generation
```bash
# Create complete policy file with header
cat > policies/mitre-attck/mitre-attck-complete.yml << EOF
# MITRE ATT&CK Framework Fleet Policies - Complete Collection
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# Source: https://github.com/teoseller/osquery-attck
# Commit: $LATEST_COMMIT
# Usage: fleetctl apply -f mitre-attck-complete.yml
---
EOF

# Combine all converted files
for yml_file in temp_yml_files/*.yml; do
    echo "# Source: $(basename "$yml_file")" >> complete.yml
    cat "$yml_file" >> complete.yml
    echo "---" >> complete.yml
done
```

---

## Error Handling Strategy

### Conversion Failures
- **Expected Behavior**: Some .conf files may fail conversion (normal)
- **Threshold**: Require at least 1 successful conversion to proceed
- **Logging**: Track success/failure counts for transparency
- **Continuation**: Process all files despite individual failures

### Network Issues
- **Retry Logic**: Git clone operations should retry on failure
- **Timeout**: 30-minute workflow timeout to prevent hanging
- **Fallback**: Manual trigger option for immediate recovery

### File System Errors
- **Validation**: Check file existence before processing
- **Cleanup**: Always clean temporary files (use `if: always()`)
- **Permissions**: Use appropriate git configuration for commits

### Fleetctl Issues
- **Installation**: Verify fleetctl installation before use
- **Version**: Log fleetctl version for debugging
- **Error Capture**: Redirect stderr to prevent sensitive info leakage

---

## Output File Specifications

### Complete Policy File Structure
```yaml
# Header with metadata
# - Generation timestamp
# - Source repository and commit
# - Usage instructions
# - Policy count

---
# Source: technique-name
apiVersion: v1
kind: pack
metadata:
  name: technique-pack
spec:
  # Fleet policy specification
---
# Next technique...
```

### Individual Technique Files
```yaml
# MITRE ATT&CK Technique: T1003-credential-dumping
# Generated: 2025-07-11 14:30:00 UTC
# Source: https://github.com/teoseller/osquery-attck
# Usage: fleetctl apply -f by-technique/T1003-credential-dumping.yml

# Fleet policy YAML content
```

### Documentation Requirements
- **Auto-generated README**: Complete usage instructions
- **Release Notes**: Detailed change information
- **File Headers**: Metadata in every generated file
- **Customer Examples**: Copy-paste deployment commands

---

## Testing Strategy

### Local Testing Script
**File**: `test-workflow-locally.sh`
**Purpose**: Mirror workflow steps for local validation
**Features**:
- Prerequisite checking (Node.js, Git, etc.)
- Progress reporting with colored output
- Error handling and cleanup
- Results analysis and next steps

### Testing Phases

#### 1. Prerequisites Validation
```bash
# Check required tools
command -v git || exit 1
command -v npm || exit 1
command -v curl || exit 1
```

#### 2. Environment Setup
```bash
# Install fleetctl using npm (matches workflow)
npm install -g fleetctl
fleetctl --version
```

#### 3. Conversion Testing
```bash
# Test single file conversion
CONF_FILE=$(find upstream -name "*.conf" | head -1)
fleetctl convert -f "$CONF_FILE" > test-output.yml
```

#### 4. Full Workflow Simulation
```bash
# Execute complete pipeline locally
./test-workflow-locally.sh
```

### Validation Criteria
- **File Generation**: All expected files created
- **Content Validation**: YAML syntax correctness
- **Header Presence**: Metadata in all files
- **Directory Structure**: Proper organization
- **Documentation**: README generation

### GitHub Actions Testing
```bash
# Using act for local GitHub Actions testing
act workflow_dispatch -W .github/workflows/update-mitre-fleet-policies.yml
```

---

## Security Considerations

### Supply Chain Security
- **Action Pinning**: Use commit SHAs instead of tags
- **Dependency Management**: Minimal external dependencies
- **Token Scope**: Least privilege permissions
- **Secret Handling**: No hardcoded credentials

### Code Injection Prevention
- **Input Validation**: Sanitize filenames and paths
- **Command Injection**: Use proper shell escaping
- **File Overwrites**: Validate output paths

### Access Control
- **Repository Permissions**: Write access for commits only
- **Token Lifecycle**: Use default GITHUB_TOKEN
- **Branch Protection**: Require successful checks

---

## Monitoring and Maintenance

### Success Metrics
- **Conversion Rate**: Percentage of successful conversions
- **File Count**: Number of policies generated
- **Update Frequency**: Actual vs. scheduled runs
- **Error Rate**: Failed workflow executions

### Alerting
- **Workflow Failures**: GitHub Actions notifications
- **Low Conversion Rate**: Manual review trigger
- **Upstream Changes**: Change detection accuracy

### Maintenance Tasks
- **Monthly**: Review failed conversions
- **Quarterly**: Update pinned action versions
- **Annually**: Review security practices

---

## Customer Usage Patterns

### Quick Deployment
```bash
# Download and apply all policies
curl -O https://raw.githubusercontent.com/org/repo/main/policies/mitre-attck/mitre-attck-complete.yml
fleetctl apply -f mitre-attck-complete.yml
```

### Selective Deployment
```bash
# Apply individual techniques
fleetctl apply -f policies/mitre-attck/by-technique/T1003-credential-dumping.yml
```

### Validation Workflow
```bash
# Test before applying
fleetctl apply --dry-run -f mitre-attck-complete.yml
fleetctl apply -f mitre-attck-complete.yml
```

---

## Implementation Checklist

### Repository Setup
- [ ] Create repository with proper structure
- [ ] Configure branch protection rules
- [ ] Set up GitHub Actions permissions

### Workflow Development
- [ ] Implement main workflow file
- [ ] Add security configurations
- [ ] Test with manual triggers

### Documentation
- [ ] Create comprehensive README template
- [ ] Add usage examples
- [ ] Document troubleshooting steps

### Testing
- [ ] Develop local testing script
- [ ] Test conversion process manually
- [ ] Validate output files with fleetctl

### Security Review
- [ ] Pin all action versions to commit SHAs
- [ ] Review permissions and token usage
- [ ] Validate input sanitization

### Launch Preparation
- [ ] Test workflow end-to-end
- [ ] Create initial release
- [ ] Document customer onboarding

---

## Success Criteria

### Functional Requirements
✅ **Automated Conversion**: .conf files → Fleet YAML policies  
✅ **Change Detection**: Only process when upstream changes  
✅ **File Organization**: Complete + individual policy files  
✅ **Documentation**: Auto-generated usage instructions  
✅ **Release Management**: Tagged releases for customer access  

### Non-Functional Requirements
✅ **Reliability**: Handle conversion failures gracefully  
✅ **Security**: Follow GitHub Actions best practices  
✅ **Performance**: Complete within 30-minute timeout  
✅ **Maintainability**: Clear code with comprehensive comments  
✅ **Usability**: Simple customer deployment process  

### Acceptance Criteria
- [ ] Workflow runs successfully on schedule
- [ ] Generates valid Fleet policy files
- [ ] Creates organized repository structure
- [ ] Provides clear customer documentation
- [ ] Handles errors without manual intervention
- [ ] Follows security best practices throughout

---

*This specification provides complete implementation guidance for the Fleet Policy Automation system. All code artifacts, testing scripts, and configuration examples are included in the accompanying files.*
