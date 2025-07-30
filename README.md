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

Or deploy by operating system:

```bash
# Linux policies (23 techniques)
fleetctl apply -f policies/linux/mitre-attck-linux.yml

# macOS policies (18 techniques)  
fleetctl apply -f policies/macos/mitre-attck-macos.yml

# Windows policies (36 techniques)
fleetctl apply -f policies/windows/mitre-attck-windows.yml
```

Or deploy specific technique files:

```bash
fleetctl apply -f policies/windows/by-technique/T1059_command_and_scripting_interpreter.yml
fleetctl apply -f policies/linux/by-technique/T1053_cron_job_discovery.yml
fleetctl apply -f policies/macos/by-technique/T1176_browser_extensions.yml
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
├── linux/                            # Linux-specific queries (23 techniques)
│   ├── by-technique/                  # Individual technique files
│   └── mitre-attck-linux.yml          # All Linux queries combined
├── macos/                            # macOS-specific queries (18 techniques)
│   ├── by-technique/                  # Individual technique files
│   └── mitre-attck-macos.yml          # All macOS queries combined
└── windows/                          # Windows-specific queries (36 techniques)
    ├── by-technique/                  # Individual technique files
    └── mitre-attck-windows.yml        # All Windows queries combined
```

### Platform-Specific Coverage

- **linux/**: 23 ATT&CK techniques covering Linux-specific monitoring (file systems, processes, users, cron jobs, sudoers, kernel modules, etc.)
- **macos/**: 18 ATT&CK techniques covering macOS-specific monitoring (processes, users, browser extensions, sudoers, setuid binaries, etc.)  
- **windows/**: 36 ATT&CK techniques covering Windows-specific monitoring (registry, services, processes, scheduled tasks, prefetch files, etc.)

## Getting Started

1. **Choose your deployment approach**:
   - **By OS**: Use `policies/linux/`, `policies/macos/`, or `policies/windows/` for platform-specific monitoring
   - **Complete**: Use `policies/mitre-attck-complete.yml` for all platforms 
   - **Individual techniques**: Use specific files from `*/by-technique/` folders
2. **Test in staging** before deploying to production
3. **Start with your primary OS** (Linux, macOS, or Windows) for focused coverage
4. **Add additional OS queries** based on your environment
5. **Tune intervals** based on your environment's needs
6. **Integrate with your SIEM** for alerting and analysis


