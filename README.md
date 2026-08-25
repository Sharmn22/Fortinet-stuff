# Fortinet Tools

A collection of scripts and tools for automating, documenting, and reporting
on Fortinet FortiGate firewalls.

## Table of Contents

- [Overview](#overview)
- [Tools](#tools)
  - [FortiGate Firewall Policy Report](#fortigate-firewall-policy-report)
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Security Notes](#security-notes)
- [License](#license)

## Overview

This repository holds standalone tools for working with FortiGate firewalls
via their REST API — reporting, documentation, and automation helpers. Each
tool lives in its own folder with its own README covering setup and usage in
detail.

## Tools

### FortiGate Firewall Policy Report

📁 [`FortiGatePolicyReport/`](./FortiGatePolicyReport)

A PowerShell script that connects to a FortiGate's REST API, pulls every
firewall policy, and generates a clean, sortable HTML report — useful for
documentation, change reviews, or compliance/audit evidence (e.g. ISO 27001).

- Reports Policy ID, Name, From/To interfaces, Source, Destination, Schedule,
  Service, Action, IP Pool NAT, Security Profiles, and Log setting
- Disabled policies are visually flagged; Action is color-coded
- Output is a single self-contained, sortable HTML file

See [`FortiGatePolicyReport/README.md`](./FortiGatePolicyReport/README.md)
for full prerequisites, configuration, and usage instructions.

## Prerequisites

Requirements vary slightly per tool — see each tool's own README for specifics
(FortiOS version compatibility, API admin setup, etc.). In general, tools in
this repo require:

- [PowerShell 7+](https://github.com/PowerShell/PowerShell/releases)
- A FortiGate REST API admin account with appropriate (usually read-only)
  permissions

## Repository Structure

```
Fortinet-tools/
├── README.md                    # This file
├── LICENSE
└── FortiGatePolicyReport/
    ├── README.md                # Tool-specific setup & usage
    └── Get-FortiGatePolicyReport.ps1
```

As more tools are added, each gets its own top-level folder and README, listed
under [Tools](#tools) above.

## Security Notes

These scripts are configured with placeholder values (FortiGate IP, API key)
that you must replace with your own before use — see each tool's README.
**Never commit real API keys, credentials, or internal IP addresses** to this
repository. If a key is ever accidentally exposed, revoke/regenerate it
immediately on the FortiGate under **System → Administrators**.

## License

This repository is licensed under the [MIT License](./LICENSE).
