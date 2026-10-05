# DNS Caching Server with BIND
A hands-on implementation of a recursive and caching DNS server using BIND 9 on Red Hat Enterprise Linux 9.

## Project Overview

This project implements a recursive and caching DNS server using BIND 9 on Red Hat Enterprise Linux 9. The server resolves DNS queries for clients on a private lab network, performs recursive lookups when records are not cached, and serves subsequent requests from its local cache.

The project also demonstrates DNS troubleshooting, network connectivity analysis, DNSSEC validation, access control, service management, and performance testing.

## Objectives

- Deploy BIND 9 on Red Hat Enterprise Linux 9.
- Configure BIND as a recursive caching DNS resolver.
- Restrict DNS queries to the private lab network.
- Configure DNSSEC validation.
- Test recursive DNS resolution using `dig`.
- Demonstrate DNS caching through repeated queries.
- Troubleshoot DNS, routing, firewall, and internet connectivity issues.
- Validate service availability and persistence after restart.

  ## Lab Environment

| Component | Details |
|---|---|
| Operating System | Red Hat Enterprise Linux 9.8 |
| DNS Software | BIND 9.16.23 |
| Server IP | 192.168.122.100 |
| DNS Port | 53 (UDP/TCP) |
| Virtualization | KVM / libvirt |
| Client Network | 192.168.122.0/24 |
| DNS Testing Tool | `dig` |
| Network Testing | `ping`, `curl` |
| Service Management | `systemctl` |


## Network Architecture

The DNS server runs inside a KVM/libvirt virtual machine on a private NAT network.

```text
                         Internet
                            │
                            ▼
                    Host DNS / Internet
                            │
                     libvirt NAT
                            │
                    192.168.122.1
                  DNS Gateway / dnsmasq
                            │
                            │
                 192.168.122.0/24
                            │
                            ▼
                ┌─────────────────────┐
                │   RHEL 9.8 VM       │
                │   juntosctl         │
                │                     │
                │ BIND 9.16.23        │
                │ 192.168.122.100     │
                │ UDP/TCP 53          │
                └─────────────────────┘
                            │
                            ▼
                     DNS Clients
DNS Request Flow

Client
  │
  │ DNS Query
  ▼
BIND @ 192.168.122.100
  │
  ├── Cached? ──────► Return cached response
  │
  └── Not cached
          │
          ▼
     Recursive lookup
          │
          ▼
      DNS hierarchy
          │
          ▼
      Return response
          │
          ▼
       Cache result
          │
          ▼
       Client

```
## Initial Problem

Before installing BIND, the RHEL virtual machine had internet connectivity but could not resolve DNS names.

Initial symptoms included:

- `ping 8.8.8.8` succeeded.
- `ping google.com` failed with `Name or service not known`.
- DNS queries to external resolvers timed out.
- `dnf` could not reach the Red Hat repositories because DNS and HTTPS connectivity from the VM were affected.

The investigation showed that the VM was connected to the libvirt NAT network, while the host firewall was restricting DNS and routed traffic.

### Root Cause

The host system was running UFW with:

- Incoming traffic: `deny`
- Routed traffic: `deny`

DNS traffic from the `192.168.122.0/24` VM network to the libvirt gateway was therefore blocked, and routed traffic from the VM to the internet was also being denied.

The issue was resolved by allowing DNS traffic to the libvirt gateway and allowing forwarding from the VM subnet.

### Firewall Resolution

The following UFW rules were added on the host:

```bash
sudo ufw allow from 192.168.122.0/24 to 192.168.122.1 port 53
sudo ufw route allow from 192.168.122.0/24

```

## BIND Installation

Once network connectivity and repository access were restored, BIND and its utilities were installed using DNF:

```bash
dnf install bind bind-utils -y
```
named -V verify installation
## BIND Configuration

The default Red Hat BIND configuration was modified to allow BIND to listen on the server's network interface and serve DNS queries from the private lab network.

### Listening Address

```conf
listen-on port 53 { 127.0.0.1; 192.168.122.100; };
allow-query { localhost; 192.168.122.0/24; };
recursion yes;
dnssec-validation yes;

config validation
named-checkconf /etc/named.conf
```

## Service Management

BIND was enabled to start automatically with the system and started immediately:

```bash
systemctl enable --now named
systemctl status named --no-pager

Bind restarted
systemctl restart named
systemctl is-active named
```
## Testing & Validation

### 1. Verify BIND is Listening

BIND was verified to be listening on DNS port 53:

```bash
ss -lunpt | grep ':53'
```
dig @192.168.122.100 google.com
dig @192.168.122.100 redhat.com

DNSSEC Validation was tested using:
dig @192.168.122.100 dnssec-failed.org

##Skills Demonstrated
- Linux system administration
- DNS fundamentals
- BIND 9
- Recursive DNS
- DNS caching
- DNSSEC
- dig
- TCP/IP
- IP addressing and subnetting
- Network troubleshooting
- Firewall troubleshooting
- UFW
- KVM/libvirt networking
- systemd service management
- Root-cause analysis
- Technical documentation
##Key Outcomes
- Successfully deployed a BIND 9 recursive caching DNS server.
- Restricted DNS access to a private lab network.
- Restored DNS and HTTPS connectivity through firewall troubleshooting.
- Demonstrated recursive DNS resolution.
- Demonstrated DNS caching with a measured response-time reduction from approximately 1981 ms to 2 ms.
- Validated DNSSEC behavior using a deliberately invalid DNSSEC domain.
- Verified BIND service persistence after restart.
##Conclusion
This project provided practical experience deploying and troubleshooting a Linux-based DNS infrastructure service. It combined networking fundamentals, Linux administration, security controls, DNS troubleshooting, recursive resolution, caching, and service management in a reproducible virtualized lab environment.
