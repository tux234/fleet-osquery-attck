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

- **163 pre-built queries** covering major ATT&CK techniques
- **Multi-platform support** for Windows, Linux, and macOS endpoints
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

Or deploy specific techniques:

```bash
fleetctl apply -f policies/by-technique/windows_powershell_events.yml
```

## What's Included

Each policy includes:
- **ATT&CK technique mapping** (e.g., T1086, T1064)
- **Platform targeting** (Windows, Linux, macOS)
- **Optimized intervals** (10min, 30min, 1hr, 8hr)
- **Descriptive names** following Fleet conventions
- **Production-ready SQL** validated against osquery tables

## Getting Started

1. **Review the policies** in `policies/by-technique/` to understand what each detects
2. **Test in staging** before deploying to production
3. **Start with high-value techniques** like credential access and lateral movement
4. **Tune intervals** based on your environment's needs
5. **Integrate with your SIEM** for alerting and analysis

Fleet makes it easy to deploy comprehensive ATT&CK-based monitoring without building queries from scratch.