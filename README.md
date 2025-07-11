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

- **Total Policies**: 26 successfully converted
- **Last Updated**: 2025-07-11 19:28:33 UTC
- **Source Commit**: 6df5f75db20f2b67f6245d1676b97ddd7005aadb
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
