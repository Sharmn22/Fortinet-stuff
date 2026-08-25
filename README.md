# FortiGate Firewall Policy Report

A PowerShell script that connects to a FortiGate's REST API, pulls all firewall
policies, and generates a clean, sortable HTML report — useful for
documentation, change reviews, or compliance/audit evidence (e.g. ISO 27001).

## Features

- Pulls every firewall policy via the FortiGate REST API (`/api/v2/cmdb/firewall/policy`)
- Report includes: Policy ID, Name, From/To interfaces, Source, Destination,
  Schedule, Service, Action, IP Pool NAT, Security Profiles, and Log setting
- Disabled policies are visually marked (greyed out, "DISABLED" badge)
- Action column is color-coded (accept = green, deny = red)
- Click any column header in the report to sort by that column
- Output is a single self-contained HTML file, timestamped and saved next to
  the script, and opened automatically when the script finishes

## Prerequisites

### 1. PowerShell 7+

This script requires **PowerShell 7 or later** (not the built-in Windows
PowerShell 5.1), because it uses `Invoke-RestMethod -SkipCertificateCheck`.

**Windows:**
```powershell
winget install --id Microsoft.PowerShell --source winget
```
Or download the installer from the official releases page:
https://github.com/PowerShell/PowerShell/releases

After installing, launch it with `pwsh` (not `powershell`).

**macOS (Homebrew):**
```bash
brew install --cask powershell
```

**Linux:**
See the official install docs for your distro:
https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux

Verify your version:
```powershell
pwsh -Version
```

### 2. A FortiGate API admin account

1. Log in to the FortiGate GUI.
2. Go to **System → Admin Profiles** and create (or reuse) a profile with at
   least **read-only** access to Firewall Policy / Objects.
3. Go to **System → Administrators → Create New → REST API Admin**.
   - Name it (e.g. `automation-ro-admin`).
   - Assign the read-only admin profile from step 2.
   - Restrict **Trusted Hosts** to the IP(s)/subnet you'll run this script
     from — strongly recommended.
4. On creation, FortiGate will show you the **API key once** — copy it
   immediately; it cannot be retrieved again later (only regenerated).
5. Confirm the API/admin HTTPS service is reachable on the port you plan to
   use (default admin HTTPS port is 443; this repo's example uses a custom
   port — adjust to match your setup).

### 3. Network access

The machine running this script must be able to reach the FortiGate's
management HTTPS port. If the FortiGate uses a self-signed certificate (the
default), the script skips certificate validation (`-SkipCertificateCheck`) —
fine for a lab/internal network, but be aware this disables TLS trust
verification.

## Configuration

Open `Get-FortiGatePolicyReport.ps1` and edit the variables at the top:

```powershell
$FortiGateIP   = "<FORTIGATE_IP>"        # FortiGate management IP or hostname
$FortiGatePort = 4443                    # HTTPS admin/API port
$ApiUser       = "automation-ro-admin"   # For reference/logging only
$ApiKey        = "<YOUR_API_KEY_HERE>"   # The REST API admin's API key
$Vdom          = "root"                 # VDOM to query
```

> ⚠️ **Security note:** The API key is stored in plaintext in this script by
> design, for simplicity on a trusted/local machine. **Never commit your real
> API key or internal IP to a public (or shared private) git repository.**
> Keep your populated copy local, or move the values into a separate
> git-ignored config file, environment variables, or a secrets manager if you
> plan to version-control this script with real values. If a key is ever
> exposed, revoke/regenerate it immediately in
> **System → Administrators** on the FortiGate.

## Usage

```powershell
pwsh ./Get-FortiGatePolicyReport.ps1
```

The script will:
1. Connect to the FortiGate REST API and retrieve all firewall policies.
2. Build an HTML report.
3. Save it as `FortiGate-Policy-Report_<timestamp>.html` in the script's folder.
4. Open the report automatically in your default browser.

## Compatibility

Tested against FortiOS 7.4.x. Should work on any FortiOS 7.0.1+ release that
supports Bearer-token REST API authentication for admin accounts. VDOM setups
other than a single `root` domain may require adjusting the `$Vdom` variable
or querying multiple VDOMs.

## License

Personal/internal use script — adapt as needed for your environment.
