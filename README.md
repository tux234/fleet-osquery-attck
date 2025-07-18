# Fleet MITRE ATT&CK Detection Policies

Ready-to-use Fleet policies for detecting adversary tactics, techniques, and procedures based on the MITRE ATT&CK framework.

## Why This Repo Exists

The [MITRE ATT&CK framework](https://attack.mitre.org/) catalogs real-world adversary tactics and techniques observed in cyberattacks. Security teams use this framework to:

- **Understand threats**: Know what attackers actually do in the wild
- **Improve detection**: Build monitoring that catches real attack patterns
- **Measure coverage**: Assess how well your security tools detect different attack types
- **Communicate risk**: Use a common language with stakeholders about threats

This repository converts community-maintained osquery configurations into Fleet-compatible policies, making it easy to deploy comprehensive ATT&CK-based monitoring across your fleet.

## What You Get

- **152 pre-built queries** covering major ATT&CK techniques
- **Platform-specific targeting** for Windows, Linux, and macOS endpoints
- **Fleet-ready format** - deploy immediately with `fleetctl`
- **Organized by technique** - understand what each query detects
- **Production-tested** - based on proven osquery configurations from [teoseller/osquery-attck](https://github.com/teoseller/osquery-attck)

## Use Cases

- **Threat hunting**: Proactively search for signs of compromise
- **Incident response**: Quickly deploy detection across your environment
- **Security assessment**: Measure your current detection capabilities
- **Compliance**: Demonstrate proactive threat monitoring to auditors
- **SOC operations**: Reduce time to deploy new detection rules

## Quick Start

Deploy all policies to your Fleet instance:

```bash
fleetctl apply -f policies/mitre-attck-complete.yml
```

Or deploy by platform compatibility:

```bash
# All platforms (Windows + Linux + macOS)
fleetctl apply -f policies/all/mitre-attck-cross-platform.yml

# Unix-like systems (Linux + macOS)  
fleetctl apply -f policies/nix/mitre-attck-unix-like.yml

# Windows-specific policies
fleetctl apply -f policies/windows/mitre-attck-windows-only.yml

# Linux-specific policies
fleetctl apply -f policies/linux/mitre-attck-linux-only.yml

# macOS-specific policies (future)
fleetctl apply -f policies/macos/mitre-attck-macos-only.yml
```

Or deploy by folder for all queries in a category:

```bash
# Deploy all cross-platform queries by folder
fleetctl apply -f policies/all/

# Deploy all Windows queries by folder  
fleetctl apply -f policies/windows/
```

Or deploy specific technique files:

```bash
fleetctl apply -f policies/windows/by-technique/T1059_command_and_scripting_interpreter.yml
```

## What's Included

Each policy includes:
- **ATT&CK technique mapping** (e.g., T1086, T1064)
- **Platform targeting** (Windows, Linux, macOS)
- **Optimized intervals** (10min, 30min, 1hr, 8hr)
- **Descriptive names** following Fleet conventions
- **Production-ready SQL** validated against osquery tables

## Folder Structure

```
policies/
├── mitre-attck-complete.yml           # All queries in one file (backward compatibility)
├── all/                               # Cross-platform queries (Windows + Linux + macOS)
│   ├── by-technique/                  # Individual technique files
│   └── mitre-attck-cross-platform.yml # All cross-platform queries
├── nix/                               # Unix-like queries (Linux + macOS)
│   ├── by-technique/                  # Individual technique files  
│   └── mitre-attck-unix-like.yml      # All Unix-like queries
├── windows/                           # Windows-specific queries
│   ├── by-technique/                  # Individual technique files
│   └── mitre-attck-windows-only.yml   # All Windows queries
├── linux/                            # Linux-specific queries
│   ├── by-technique/                  # Individual technique files
│   └── mitre-attck-linux-only.yml     # All Linux queries
└── macos/                            # macOS-specific queries (ready for future use)
    ├── by-technique/                  # Individual technique files
    └── mitre-attck-macos-only.yml     # All macOS queries
```

### Platform Categories

- **all/**: Queries using universal osquery tables (processes, users, etc.) that work on all platforms
- **nix/**: Queries using Unix-specific tables (mounts, chrome_extensions, etc.) for Linux and macOS
- **linux/**: Queries using Linux-specific paths or features not available on macOS
- **windows/**: Queries using Windows-specific tables (registry, powershell_events, etc.)
- **macos/**: Ready for future macOS-specific queries

## Getting Started

1. **Choose your deployment approach**:
   - **Cross-platform**: Use `policies/all/` for queries that work on all operating systems
   - **Unix-like**: Use `policies/nix/` for Linux and macOS environments  
   - **Platform-specific**: Use `policies/windows/`, `policies/linux/`, or `policies/macos/`
   - **Complete**: Use `policies/mitre-attck-complete.yml` for all platforms (backward compatibility)
   - **Individual techniques**: Use specific files from `*/by-technique/` folders
2. **Test in staging** before deploying to production
3. **Start with cross-platform queries** from `all/` for broad coverage
4. **Add platform-specific queries** based on your environment
5. **Tune intervals** based on your environment's needs
6. **Integrate with your SIEM** for alerting and analysis

## Research-Based Organization

This repository organizes queries based on comprehensive research of osquery table compatibility:

- **Universal Tables**: Queries in `all/` use tables available on Windows, Linux, and macOS (processes, users, logged_in_users, etc.)
- **Unix-Specific Tables**: Queries in `nix/` use POSIX tables (mounts, suid_bin, sudoers, chrome_extensions, etc.)
- **Platform-Specific Features**: Platform folders contain queries using OS-specific tables or file paths
- **Verified Compatibility**: All categorizations verified against official osquery documentation and specs

Fleet makes it easy to deploy comprehensive ATT&CK-based monitoring without building queries from scratch.