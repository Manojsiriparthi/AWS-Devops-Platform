# AWS VPC Networking - Complete Explanation (Foundation to Advanced)

## Table of Contents
1. [What is a VPC?](#what-is-a-vpc)
2. [Why Do We Need a VPC?](#why-do-we-need-a-vpc)
3. [VPC Components Breakdown](#vpc-components-breakdown)
4. [How Traffic Flows](#how-traffic-flows)
5. [Why We Enable DNS Support & Hostnames](#dns-settings)
6. [Our Project's Network Architecture](#our-architecture)
7. [Real-World Analogy](#real-world-analogy)

---

## What is a VPC?

**VPC = Virtual Private Cloud**

Think of it as YOUR OWN private data center inside AWS. When you create a VPC, you get an isolated section of the AWS cloud where you control:
- What IP addresses are used
- Which resources can talk to each other
- What can access the internet
- What is hidden from the outside world

**Without a VPC:** All your resources (servers, databases) would be floating in the open, accessible by anyone.

**With a VPC:** You define boundaries, like walls around your house, and YOU decide who gets in and who doesn't.

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS CLOUD                             │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              YOUR VPC (10.0.0.0/16)                  │   │
│   │         = Your private data center                   │   │
│   │         = 65,536 IP addresses to use                 │   │
│   │                                                     │   │
│   │   Only YOU control what happens in here             │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### CIDR Block (IP Address Range)

When you create a VPC, you assign it a **CIDR block** — this defines how many IP addresses you have.

```
10.0.0.0/16 = 65,536 addresses (10.0.0.0 to 10.0.255.255)
10.0.0.0/24 = 256 addresses    (10.0.0.0 to 10.0.0.255)
```

The smaller the number after `/`, the MORE addresses you get:
- /16 = 65,536 IPs (good for VPC)
- /24 = 256 IPs (good for subnets)

---

## Why Do We Need a VPC?

| Without VPC | With VPC |
|-------------|----------|
| No isolation — anyone can reach your DB | DB is in private subnet, unreachable from internet |
| No control over IP ranges | You define exact IP structure |
| Can't separate dev/qa/prod | Each env gets its own VPC with unique CIDR |
| No network-level security | Security Groups + NACLs filter traffic |
| Single point of failure | Multi-AZ subnets for high availability |

---

## VPC Components Breakdown

### 1. Subnets (Public vs Private)

A **subnet** is a smaller slice of your VPC's IP range, placed in a specific Availability Zone (physical data center).

#### Public Subnet
- **HAS** a route to the Internet Gateway
- Resources here CAN be directly accessed from the internet
- Used for: Load Balancers, Bastion/Jump servers, NAT Gateways

#### Private Subnet
- **NO** direct route to the internet
- Resources here CANNOT be reached from outside
- Used for: Application servers, Databases, Internal services

```
┌────────────────────────── VPC (10.0.0.0/16) ──────────────────────────┐
│                                                                        │
│   ┌──────────────────────┐        ┌──────────────────────┐            │
│   │   PUBLIC SUBNET       │        │   PRIVATE SUBNET      │            │
│   │   10.0.1.0/24        │        │   10.0.10.0/24        │            │
│   │                      │        │                      │            │
│   │   ✅ Internet access  │        │   ❌ No internet      │            │
│   │   ✅ Public IPs       │        │   ❌ No public IPs    │            │
│   │                      │        │                      │            │
│   │   • Load Balancer    │        │   • App Servers       │            │
│   │   • Bastion Server   │───────▶│   • Databases         │            │
│   │   • NAT Gateway      │        │   • Cache (Redis)     │            │
│   └──────────────────────┘        └──────────────────────┘            │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

**Why separate them?**
- Your database should NEVER be directly accessible from the internet
- Attackers can't reach what they can't see
- Principle of least privilege: only expose what's necessary

---

### 2. Internet Gateway (IGW)

**What:** The "front door" of your VPC that connects it to the public internet.

**Why:** Without it, NOTHING in your VPC can reach the internet (and the internet can't reach your VPC).

```
    INTERNET
       │
       ▼
┌──────────────┐
│   Internet   │   ← Only ONE per VPC
│   Gateway    │   ← Free (no hourly cost)
└──────┬───────┘   ← Highly available by default
       │
       ▼
   PUBLIC SUBNET (has route: 0.0.0.0/0 → IGW)
```

**Key points:**
- One IGW per VPC (you can't have multiple)
- It's a two-way door: traffic goes OUT and comes IN
- Only public subnets have a route pointing to it
- It's AWS-managed and horizontally scaled (you don't worry about capacity)

---

### 3. NAT Gateway

**What:** Allows resources in PRIVATE subnets to reach the internet (for updates, API calls) WITHOUT exposing them to incoming traffic.

**Why:** Your app server in a private subnet needs to:
- Download software updates (`apt update`)
- Call external APIs (payment gateways, email services)
- Pull Docker images from registries

But you DON'T want anyone from the internet to initiate a connection TO that server.

```
    INTERNET
       │
       ▼
┌──────────────┐
│   Internet   │
│   Gateway    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│     NAT      │   ← Sits IN a public subnet
│   Gateway    │   ← One-way: outbound only
└──────┬───────┘   ← Costs ~$0.045/hour + data transfer
       │
       ▼
   PRIVATE SUBNET (route: 0.0.0.0/0 → NAT Gateway)
```

**NAT = Network Address Translation**
- Private server says: "I need to reach google.com"
- NAT Gateway translates the private IP to its public Elastic IP
- Google sees the NAT's public IP, not the private server
- Response comes back through NAT → forwarded to private server
- Google can NEVER initiate a connection to the private server

**IGW vs NAT Gateway:**

| | Internet Gateway | NAT Gateway |
|--|-----------------|-------------|
| Direction | Two-way (in + out) | One-way (out only) |
| Used by | Public subnets | Private subnets |
| Cost | Free | ~$32/month + data |
| Allows inbound | Yes | No |
| Location | VPC-level | Inside a public subnet |

---

### 4. Elastic IP (EIP)

**What:** A static, permanent public IP address that you own until you release it.

**Why NAT Gateway needs one:**
- NAT Gateway must have a fixed public IP
- Without Elastic IP, the NAT's public IP could change on restart
- External APIs that whitelist your IP need it to stay constant
- Logs and monitoring need a consistent source IP

```
┌──────────────┐
│  Elastic IP  │  ← Fixed: 54.23.45.67 (never changes)
│  (EIP)       │  ← Attached to NAT Gateway
└──────┬───────┘
       │
       ▼
┌──────────────┐
│     NAT      │  ← All outbound traffic from private subnet
│   Gateway    │     appears to come from 54.23.45.67
└──────────────┘
```

**Cost note:** EIP is free ONLY when attached to a running resource. If you allocate one and don't use it, AWS charges you (~$3.65/month). This prevents IP hoarding.

---

### 5. Route Tables

**What:** A set of rules (routes) that determine WHERE network traffic goes.

Every subnet MUST be associated with a route table. Think of it as a GPS for packets.

```
PUBLIC SUBNET ROUTE TABLE:
┌────────────────────┬──────────────────┐
│ Destination        │ Target           │
├────────────────────┼──────────────────┤
│ 10.0.0.0/16       │ local            │  ← Traffic within VPC stays local
│ 0.0.0.0/0         │ Internet Gateway │  ← Everything else → internet
└────────────────────┴──────────────────┘

PRIVATE SUBNET ROUTE TABLE:
┌────────────────────┬──────────────────┐
│ Destination        │ Target           │
├────────────────────┼──────────────────┤
│ 10.0.0.0/16       │ local            │  ← Traffic within VPC stays local
│ 0.0.0.0/0         │ NAT Gateway      │  ← Everything else → NAT (outbound only)
└────────────────────┴──────────────────┘
```

**What makes a subnet "public" vs "private"?**
- It's NOT a setting on the subnet itself
- It's determined by the ROUTE TABLE: if it has a route to an IGW → public
- No IGW route → private

---

### 6. Security Groups (SG)

**What:** A virtual firewall attached to individual resources (EC2, RDS, etc.). Controls INBOUND and OUTBOUND traffic at the instance level.

**Key characteristics:**
- **Stateful** — if you allow inbound traffic, the response is automatically allowed out (and vice versa)
- **Allow rules only** — you can only specify what to ALLOW (no deny rules)
- **Default:** blocks all inbound, allows all outbound

```
SECURITY GROUP: web-sg
┌─────────────────────────────────────────────────────────────┐
│ INBOUND RULES:                                              │
│   Port 80  (HTTP)  ← from 0.0.0.0/0 (anyone)             │
│   Port 443 (HTTPS) ← from 0.0.0.0/0 (anyone)             │
│   Port 22  (SSH)   ← from bastion-sg only (not everyone!) │
│                                                             │
│ OUTBOUND RULES:                                             │
│   All traffic      → to 0.0.0.0/0 (allow all outbound)    │
└─────────────────────────────────────────────────────────────┘
```

**Why we have 3 security groups in our project:**

| SG | Attached To | Allows Inbound From |
|----|-------------|-------------------|
| bastion-sg | Jump server | SSH from your IP |
| web-sg | App servers | HTTP/HTTPS from internet, SSH from bastion only |
| db-sg | Databases | Port 3306/5432 from web-sg only |

**This creates a chain:**
```
Internet → bastion-sg → web-sg → db-sg
                                    │
            You can NEVER reach the DB directly from internet
```

---

### 7. Network ACLs (NACLs)

**What:** A firewall at the SUBNET level (not instance level). Controls traffic entering and leaving the entire subnet.

**SG vs NACL:**

| | Security Group | NACL |
|--|---------------|------|
| Level | Instance (EC2, RDS) | Subnet |
| Stateful? | Yes (responses auto-allowed) | No (must allow both directions) |
| Rules | Allow only | Allow AND Deny |
| Evaluation | All rules checked together | Rules evaluated in NUMBER ORDER |
| Default | Deny all inbound | Allow all (default NACL) |

**Why use BOTH?**
- Defense in depth: two layers of security
- NACL = broad subnet-level filter (block entire IP ranges)
- SG = fine-grained instance-level control (allow only specific ports)

```
TRAFFIC FLOW:
Internet → NACL (subnet filter) → Security Group (instance filter) → EC2
                                                                        
Both must ALLOW the traffic, or it gets dropped.
```

---

## DNS Settings

### `enable_dns_support = true`

**What it does:** Enables the Amazon-provided DNS server for your VPC (at VPC CIDR + 2, e.g., 10.0.0.2).

**Why you need it:**
- Without this, resources in your VPC can't resolve domain names
- `apt update` won't work (can't resolve archive.ubuntu.com)
- Internal service discovery won't work
- Basically: nothing useful works without DNS

### `enable_dns_hostnames = true`

**What it does:** Automatically assigns a public DNS hostname to instances with public IPs.

**Why you need it:**
- EC2 gets a hostname like `ec2-54-23-45-67.compute-1.amazonaws.com`
- Required for certain AWS services (like EFS, VPC endpoints)
- Makes it easier to connect to instances (hostname instead of memorizing IPs)
- Required if you want to use private hosted zones (Route 53)

```
Without dns_hostnames: You must use IP → ssh ec2-user@54.23.45.67
With dns_hostnames:    You can use DNS → ssh ec2-user@ec2-54-23-45-67.compute-1.amazonaws.com
```

---

## How Traffic Flows

### Scenario 1: User accesses your web app

```
User (internet) 
  → Internet Gateway 
    → Public Subnet (Load Balancer) 
      → Private Subnet (App Server) 
        → Private Subnet (Database)
          → Response flows back the same path
```

### Scenario 2: App server needs to download updates

```
App Server (private subnet, no public IP)
  → Route table says 0.0.0.0/0 → NAT Gateway
    → NAT Gateway (in public subnet, has Elastic IP)
      → Internet Gateway
        → Internet (apt repository / Docker Hub / etc.)
          → Response comes back through NAT → App Server
```

### Scenario 3: SSH into a private server

```
You (your laptop)
  → SSH to Bastion (public subnet, port 22 open to your IP)
    → From Bastion, SSH to App Server (private subnet, port 22 open to bastion-sg)
      → You're now inside the private server
         (the app server was NEVER exposed to the internet directly)
```

---

## Our Architecture

### Why 3 Separate VPCs (dev / qa / prod)?

```
DEV  VPC: 10.0.0.0/16  ← Developers experiment here, can break things
QA   VPC: 10.1.0.0/16  ← Testing environment, mirrors production
PROD VPC: 10.2.0.0/16  ← Live traffic, maximum security & availability
```

**Reasons:**
1. **Isolation** — a mistake in dev can NEVER affect prod
2. **Security** — prod has stricter rules (no open SSH, multi-AZ NAT)
3. **Compliance** — auditors require environment separation
4. **Cost control** — dev uses single NAT (cheaper), prod uses multi-NAT (reliable)

### Dev vs Prod Differences

| | Dev | Prod |
|--|-----|------|
| AZs | 2 (cost saving) | 3 (high availability) |
| NAT Gateway | 1 shared (if it dies, dev is briefly offline — acceptable) | 1 per AZ (if one dies, others keep working) |
| Bastion SSH | Open to 0.0.0.0/0 (easy access for devs) | Restricted to known IPs only |
| State file | envs/dev/network/terraform.tfstate | envs/prod/network/terraform.tfstate |

---

## Real-World Analogy

Think of it like a **corporate office building:**

| AWS Concept | Office Analogy |
|-------------|---------------|
| **VPC** | The entire building + property |
| **CIDR Block** | The building's address range (floors 1-10) |
| **Public Subnet** | Reception/lobby (visitors can walk in) |
| **Private Subnet** | Server room (badge access only, no visitors) |
| **Internet Gateway** | The main entrance door |
| **NAT Gateway** | A one-way mail slot (you can send mail out, but nobody can push mail in) |
| **Elastic IP** | The building's fixed street address |
| **Route Table** | Signs that say "Visitors → Lobby, Staff → Offices" |
| **Security Group** | The lock on each individual room door |
| **NACL** | The security guard at each floor's elevator entrance |
| **Bastion Host** | The front desk receptionist (you must check in here first) |

---

## Quick Reference: What Goes Where

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           VPC (10.0.0.0/16)                             │
│                                                                         │
│         Availability Zone A          Availability Zone B                │
│   ┌─────────────────────────┐  ┌─────────────────────────┐            │
│   │    PUBLIC 10.0.1.0/24   │  │    PUBLIC 10.0.2.0/24   │            │
│   │                         │  │                         │            │
│   │  • ALB (Load Balancer)  │  │  • ALB (Load Balancer)  │            │
│   │  • NAT Gateway + EIP   │  │  • Bastion Host         │            │
│   └────────────┬────────────┘  └────────────┬────────────┘            │
│                │                             │                         │
│   ┌────────────▼────────────┐  ┌────────────▼────────────┐            │
│   │   PRIVATE 10.0.10.0/24  │  │   PRIVATE 10.0.20.0/24  │            │
│   │                         │  │                         │            │
│   │  • EC2 App Servers      │  │  • EC2 App Servers      │            │
│   │  • RDS Database         │  │  • RDS Standby          │            │
│   │  • ElastiCache          │  │  • ElastiCache Replica  │            │
│   └─────────────────────────┘  └─────────────────────────┘            │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
         │                                        ▲
         │         ┌──────────────────┐           │
         └────────▶│ Internet Gateway │───────────┘
                   └────────┬─────────┘
                            │
                       INTERNET
```

---

## Summary: Why Each Component Exists

| Component | One-Line Purpose |
|-----------|-----------------|
| VPC | Your isolated private network in AWS |
| Public Subnet | For resources that NEED internet access from outside |
| Private Subnet | For resources that must NEVER be directly reachable |
| Internet Gateway | The door between your VPC and the internet |
| NAT Gateway | Lets private resources reach internet without being exposed |
| Elastic IP | Fixed public IP so NAT's address never changes |
| Route Table | Rules that tell traffic where to go |
| Security Group | Per-instance firewall (allow rules, stateful) |
| NACL | Per-subnet firewall (allow + deny rules, stateless) |
| DNS Support | So your resources can resolve domain names |
| DNS Hostnames | So your resources get human-readable DNS names |

---

## Next Steps

Now that you understand the WHY behind each component, look at the actual Terraform code:
- `modules/network/main.tf` — See how each component above is created in code
- `modules/network/security_groups.tf` — See the SG chain (bastion → web → db)
- `modules/network/nacl.tf` — See subnet-level rules
- `environments/dev/terraform.tfvars` — See how values differ per environment
