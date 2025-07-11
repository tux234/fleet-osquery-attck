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

- **Total Policies**: *Will be updated automatically*
- **Last Updated**: *Will be updated automatically*
- **Source Commit**: *Will be updated automatically*
- **Update Schedule**: Weekly (Mondays at 2 AM UTC)

## Automation

This repository is automatically updated weekly via GitHub Actions when changes are detected in the upstream [teoseller/osquery-attck](https://github.com/teoseller/osquery-attck) repository. The automation:

- Monitors the upstream repository for changes
- Converts osquery `.conf` files to Fleet-compatible YAML policies
- Generates both complete and individual technique files
- Creates releases with downloadable policy files
- Updates documentation automatically

## Usage Notes

- All policies are automatically generated from upstream osquery configurations
- Policies are updated weekly when changes are detected in the source repository
- Each policy file includes metadata about its source and generation time
- Use `fleetctl apply --dry-run` to validate policies before deployment
- Individual technique files allow for granular deployment

## Local Development

### Testing the Automation Locally

To test the policy generation process locally:

```bash
# Make the script executable
chmod +x test-workflow-locally.sh

# Run the local testing script
./test-workflow-locally.sh

# Force update even if no changes detected
./test-workflow-locally.sh --force

# View help
./test-workflow-locally.sh --help
```

### Prerequisites

- Node.js 20 (LTS)
- Git
- npm
- Fleet CLI (fleetctl) - automatically installed by the script

### Manual Workflow Trigger

You can manually trigger the GitHub Actions workflow with the "force update" option:

1. Go to the Actions tab in this repository
2. Select "Update MITRE ATT&CK Fleet Policies"
3. Click "Run workflow"
4. Check "Force update even if no changes detected" if needed

## Requirements

### For Using Policies
- Fleet server with appropriate permissions
- fleetctl CLI tool installed
- Network access to download policy files

### For Development
- Node.js 20 (LTS)
- Git
- npm (for fleetctl installation)

## File Organization

### Complete Policy File
- **Location**: `policies/mitre-attck/mitre-attck-complete.yml`
- **Content**: All converted policies in a single file
- **Usage**: Deploy all MITRE ATT&CK techniques at once

### Individual Technique Files
- **Location**: `policies/mitre-attck/by-technique/`
- **Content**: One file per MITRE technique
- **Usage**: Deploy specific techniques selectively

## Security Considerations

- All GitHub Actions use pinned versions with commit SHAs for security
- Minimal permissions are granted to the automation workflow
- No secrets or credentials are hardcoded in the repository
- Input validation and sanitization are implemented throughout

## Support

### Policy Content Issues
For issues with the policies themselves, please refer to the upstream [osquery-attck](https://github.com/teoseller/osquery-attck) repository.

### Fleet-Specific Questions
Consult the [Fleet documentation](https://fleetdm.com/docs) for Fleet-specific configuration and deployment guidance.

### Automation Issues
For issues with the automation workflow or generated files, please open an issue in this repository.

## Contributing

This repository is primarily automated, but contributions are welcome for:

- Improving the automation workflow
- Enhancing documentation
- Adding validation tests
- Fixing bugs in the conversion process

## License

The automation code in this repository follows the same license as the upstream osquery-attck project. Generated policies are derived works and maintain the original licensing terms.