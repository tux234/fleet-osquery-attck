# Fleet MITRE ATT&CK Detection Policies - Implementation Plan

## Project Overview

This plan outlines the step-by-step implementation of an automated system that converts MITRE ATT&CK osquery configurations from the `teoseller/osquery-attck` repository into Fleet-compatible YAML policies. The system provides weekly automated updates with both complete and granular deployment options for customers.

## Implementation Strategy

**Approach**: Incremental development with testable milestones
**Security**: GitHub Actions best practices with pinned versions
**Testing**: Local validation script + comprehensive error handling
**Integration**: Each step builds on previous work with no orphaned code

---

## Phase 1: Foundation Setup

### Step 1: GitHub Actions Infrastructure
**Objective**: Create secure GitHub Actions workflow foundation
**Time**: 1-2 hours
**Dependencies**: None

```text
Create the GitHub Actions workflow infrastructure for the Fleet MITRE ATT&CK automation project.

Requirements:
1. Create `.github/workflows/update-mitre-fleet-policies.yml` with:
   - Secure permissions (contents: write, actions: read, metadata: read)
   - Weekly schedule trigger (Mondays 2 AM UTC: '0 2 * * 1')
   - Manual workflow_dispatch trigger with force_update boolean option
   - Security-hardened action versions (use commit SHAs from spec.md)

2. Set up environment variables:
   - UPSTREAM_REPO: 'https://github.com/teoseller/osquery-attck.git'
   - COMMIT_TRACKING_FILE: '.last_osquery_commit'
   - POLICIES_DIR: 'policies/mitre-attck'
   - TECHNIQUES_DIR: 'policies/mitre-attck/by-technique'

3. Create initial job structure with:
   - ubuntu-24.04 runner
   - Pinned actions/checkout step
   - Basic workflow validation

Follow GitHub Actions security best practices and validate the workflow syntax.
```

### Step 2: Node.js Environment Setup
**Objective**: Configure Node.js environment for Fleet CLI
**Time**: 30 minutes
**Dependencies**: Step 1

```text
Add Node.js environment setup to the GitHub Actions workflow.

Requirements:
1. Add pinned actions/setup-node step after checkout
2. Configure Node.js version 20 (LTS) as specified in requirements
3. Add npm cache configuration for performance
4. Install Fleet CLI globally using npm
5. Add Fleet CLI version logging for debugging
6. Include error handling for installation failures

Extend the existing workflow file with proper Node.js setup and Fleet CLI installation.
Ensure the setup is robust and includes proper error messages.
```

### Step 3: Upstream Repository Integration
**Objective**: Implement upstream change detection system
**Time**: 1-2 hours
**Dependencies**: Step 2

```text
Implement the upstream repository cloning and change detection logic.

Requirements:
1. Clone the upstream repository (teoseller/osquery-attck) to temp directory
2. Extract the latest commit SHA using git rev-parse
3. Compare with stored commit in .last_osquery_commit file
4. Set HAS_CHANGES environment variable based on comparison
5. Handle first-run scenario when no stored commit exists
6. Respect force_update workflow input parameter
7. Add proper error handling for git operations
8. Include cleanup for temporary directories

The logic should only proceed with conversion if changes are detected or force_update is true.
Add comprehensive logging for debugging and transparency.
```

---

## Phase 2: Core Conversion Pipeline

### Step 4: Configuration File Discovery
**Objective**: Implement robust .conf file discovery system
**Time**: 1 hour
**Dependencies**: Step 3

```text
Create the configuration file discovery and validation system.

Requirements:
1. Use find command to locate all .conf files recursively in upstream repo
2. Save file list to conf_files_list.txt for processing
3. Validate that at least one .conf file was found
4. Count total files and log for transparency
5. Add error handling for empty results
6. Create validation to ensure files are readable
7. Filter out any non-.conf files that might match the pattern

The system should be robust and provide clear error messages if no files are found.
Include proper logging of file discovery results.
```

### Step 5: Fleet CLI Conversion Engine
**Objective**: Implement the core osquery to Fleet YAML conversion
**Time**: 2-3 hours
**Dependencies**: Step 4

```text
Implement the core conversion engine that processes .conf files into Fleet YAML policies.

Requirements:
1. Create conversion loop that processes each .conf file
2. Use fleetctl convert command for each file
3. Save output to temp_yml_files directory with proper naming
4. Track success and failure counts for transparency
5. Handle conversion failures gracefully (some files expected to fail)
6. Validate output files are not empty before counting as success
7. Remove empty or failed conversion files
8. Continue processing even if individual files fail
9. Require at least 1 successful conversion to proceed
10. Add detailed logging with file-by-file status

The conversion should be resilient to individual file failures while maintaining overall progress.
Include comprehensive error handling and status reporting.
```

---

## Phase 3: Output Generation

### Step 6: Policy File Generation System
**Objective**: Create organized policy file output with metadata
**Time**: 2 hours
**Dependencies**: Step 5

```text
Implement the policy file generation system that creates organized output files.

Requirements:
1. Create the complete policy file (mitre-attck-complete.yml) with:
   - Detailed header including generation time, source commit, policy count
   - Combined content from all successful conversions
   - Proper YAML document separators (---)
   - Source file attribution for each policy section

2. Create individual technique files in by-technique/ directory with:
   - Individual headers with technique name and metadata
   - Single policy per file for granular deployment
   - Consistent naming convention
   - Usage instructions in headers

3. Ensure proper directory structure creation
4. Add file size validation and content verification
5. Include metadata tracking for documentation generation

All generated files should include proper headers with generation timestamps and source attribution.
```

### Step 7: Documentation Generation
**Objective**: Implement auto-generated documentation system
**Time**: 1-2 hours
**Dependencies**: Step 6

```text
Create the automated documentation generation system.

Requirements:
1. Generate README.md with:
   - Current policy count and last update time
   - Source commit information
   - Complete usage examples for deployment
   - Repository structure documentation
   - Validation and testing instructions

2. Update placeholder values dynamically:
   - Replace __POLICY_COUNT__ with actual successful conversions
   - Replace __GENERATION_TIME__ with current UTC timestamp
   - Replace __SOURCE_COMMIT__ with upstream commit SHA

3. Include comprehensive usage examples:
   - Complete policy deployment commands
   - Individual technique deployment
   - Validation with fleetctl --dry-run

4. Add troubleshooting and support information
5. Ensure documentation is customer-ready

The documentation should be complete and ready for customer consumption without manual editing.
```

---

## Phase 4: Validation & Error Handling

### Step 8: YAML Validation System
**Objective**: Add comprehensive validation and testing
**Time**: 1-2 hours
**Dependencies**: Step 7

```text
Implement comprehensive validation system for generated YAML files.

Requirements:
1. Add YAML syntax validation using fleetctl or yamllint
2. Perform dry-run validation with fleetctl apply --dry-run
3. Validate file structure and required fields
4. Check for proper Fleet policy format compliance
5. Verify all generated files have content and proper headers
6. Add file size and content quality checks
7. Create validation report with pass/fail status
8. Fail the workflow if critical validations fail

Include comprehensive logging of validation results and clear error messages for failures.
The validation should catch common issues before files are committed.
```

### Step 9: Comprehensive Error Handling
**Objective**: Implement robust error handling and recovery
**Time**: 1-2 hours
**Dependencies**: Step 8

```text
Add comprehensive error handling and recovery mechanisms throughout the workflow.

Requirements:
1. Add try-catch blocks around critical operations
2. Implement graceful degradation for non-critical failures
3. Create detailed error logging with context information
4. Add workflow failure conditions for critical errors
5. Implement proper cleanup in error scenarios
6. Add retry logic for network operations
7. Include timeout handling for long-running operations
8. Create error summary reporting
9. Ensure sensitive information is not logged

The error handling should be comprehensive while maintaining workflow reliability.
Include clear error messages that help with debugging and resolution.
```

---

## Phase 5: Integration & Finalization

### Step 10: Commit and Release Management
**Objective**: Implement git operations and release creation
**Time**: 1-2 hours
**Dependencies**: Step 9

```text
Add git commit operations and release management to complete the automation.

Requirements:
1. Update .last_osquery_commit with latest upstream commit
2. Configure git user for automated commits
3. Add and commit all generated files with descriptive message
4. Create tagged release using softprops/action-gh-release
5. Include release notes with:
   - Number of policies updated
   - Source commit information
   - Generation timestamp
   - File download links

6. Handle git conflicts and merge issues
7. Add verification that commit was successful
8. Include proper commit message formatting

The commit and release process should be automated and include proper error handling.
Ensure releases are properly tagged and include downloadable assets.
```

### Step 11: Local Testing Script Enhancement
**Objective**: Enhance local testing script with validation features
**Time**: 1-2 hours
**Dependencies**: Step 10

```text
Enhance the existing test-workflow-locally.sh script with comprehensive validation.

Requirements:
1. Add YAML syntax validation to local testing
2. Include fleetctl dry-run validation
3. Add file structure verification
4. Include dependency version checking
5. Add comprehensive error reporting
6. Create validation summary with pass/fail status
7. Add option to test individual components
8. Include performance timing information
9. Add cleanup verification

The enhanced script should mirror the GitHub Actions validation completely.
Ensure local testing provides same confidence as the CI environment.
```

### Step 12: End-to-End Integration Testing
**Objective**: Validate complete system integration
**Time**: 2-3 hours
**Dependencies**: Step 11

```text
Create comprehensive end-to-end integration testing for the complete system.

Requirements:
1. Test complete workflow from start to finish
2. Validate all components work together properly
3. Test error scenarios and recovery mechanisms
4. Verify output quality and customer usability
5. Test both scheduled and manual workflow triggers
6. Validate security configurations
7. Test with various upstream repository states
8. Verify documentation accuracy and completeness
9. Test local script matches GitHub Actions behavior

Include comprehensive test reporting and validation of all success criteria.
Ensure the system is production-ready and reliable.
```

---

## Implementation Guidelines

### Code Quality Standards
- **Security**: Pin all action versions to commit SHAs
- **Reliability**: Include comprehensive error handling
- **Maintainability**: Add detailed comments and logging
- **Testability**: Ensure each component can be tested independently

### Integration Requirements
- Each step must build on previous work
- No orphaned or unused code
- All components must be wired together properly
- Comprehensive validation at each stage

### Success Criteria
- Workflow runs successfully on schedule
- Generates valid Fleet policy files
- Creates organized repository structure
- Provides clear customer documentation
- Handles errors without manual intervention
- Follows security best practices throughout

---

## Risk Mitigation

### Technical Risks
- **Upstream changes**: Robust change detection and validation
- **Conversion failures**: Graceful handling of individual file failures
- **Security vulnerabilities**: Pinned versions and input validation
- **Performance issues**: Timeout handling and resource management

### Operational Risks
- **False positives**: Change detection validation
- **Failed deployments**: Comprehensive testing and validation
- **Customer issues**: Clear documentation and examples
- **Maintenance burden**: Automated testing and monitoring

---

## Post-Implementation Maintenance

### Monitoring
- Weekly workflow execution status
- Conversion success rates
- Error patterns and trends
- Customer usage feedback

### Updates
- Monthly action version reviews
- Quarterly security assessments
- Annual process improvements
- Continuous documentation updates

This plan provides a complete roadmap for implementing the Fleet MITRE ATT&CK detection policies automation system with security, reliability, and maintainability as core principles.