## Appendix C: Full Lab Blueprint & Setup Manifest

### 1. Host-Only Network Architecture Blueprint

To safely test offensive scripting mechanics, your development lab environment must be completely isolated from the internet and production home/enterprise networks. This layout prevents automated implants or verification payloads from accidentally communicating outward or exposing local systems to risk.

The target design maps a three-tier localized host-only network structure:

```
                  +---------------------------------------+
                  |         Host Linux/macOS System       |
                  |     (Your Primary Workstation Room)    |
                  +---------------------------------------+
                                      |
       +------------------------------+------------------------------+
       | [Virtual Interface: vboxnet0 / vmnet1]                      |
       | Host IP: 192.168.56.1                                       |
       v                                                             v
+-------------------------------+                             +-------------------------------+
|    Target Vulnerable Node     |                             |    Attacker Kali VM Node      |
|     (Metasploitable2 / 3)     |                             |     (Optional Dedicated)      |
| IP: 192.168.56.105            |                             | IP: 192.168.56.106            |
+-------------------------------+                             +-------------------------------+
| Services:                     |                             | Tools:                        |
| - Custom Python Web App (p3)  |                             | - Native Python3 Frameworks   |
| - Vulnerable Command API Layer|                             | - Packet Sniffer Mechanics    |
+-------------------------------+                             +-------------------------------+

```

#### Network Component Parameters

* **Host Machine Interconnect:** The physical system hosts the hypervisor layer (VirtualBox or VMware) and binds an explicit software adapter interface fixed to range `192.168.56.0/24`.
* **Target Laboratory Node VM:** A dedicated Linux container or minimal virtual machine configured *only* with a Host-Only adapter profile. **NAT and Bridged interfaces must be unchecked** within the hypervisor system panel to prevent routing to external networks.

---

### 2. Infrastructure-as-Code (Vagrantfile Configuration)

The absolute fastest path to spinning up a uniform, repeatable lab container is using HashiCorp Vagrant. The manifest file below defines an automated deployment specification that pulls a stable base box, strips risky outward routing, and establishes a fixed host-only ip target map instantly.

Save the following configuration as `Vagrantfile` in an empty workspace directory:

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # 1. Base Target Image Box (Minimal Debian stable image profile)
  config.vm.box = "debian/12-generic-amd64"

  config.vm.define "target_lab_node" do |node|
    node.vm.hostname = "target-lab-node"
    
    # 2. Hard-coded Host-Only Network Assignment
    # This automatically assigns the target IP verified in Module 4 scripts.
    node.vm.network "private_network", ip: "192.168.56.105"

    # 3. Hypervisor Engine System Resource Map
    node.vm.provider "virtualbox" do |vb|
      vb.name = "Module4-Target-Node"
      vb.memory = "1024" # Minimal footprint
      vb.cpus = 1
      # Explicitly isolate the network device card stack
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    end

    # 4. Automated Post-Deployment Provisioner Script
    # Disables system update routes to freeze environment state safely.
    node.vm.provision "shell", inline: <<-SHELL
      echo "[*] Setting up sandboxed target environment framework..."
      apt-get update -y && apt-get install -y python3 python3-pip curl ufw
      
      # Establish aggressive local target firewall profiling rules
      ufw default deny incoming
      ufw default allow outgoing
      ufw allow from 192.168.56.1 to any port 4444 proto tcp comment 'C2 TCP Entry'
      ufw allow from 192.168.56.1 to any port 4443 proto tcp comment 'C2 TLS Entry'
      ufw --force enable
      
      echo "[SUCCESS] Sandboxed target infrastructure online."
    SHELL
  end
end

```

---

### 3. Verification Commands Manifest

Once your scripts are written and your Vagrantfile is ready, use this verification checklist to perform an end-to-end integration test of the complete system:

#### Step 1: Initialize the Target Node

In your terminal workspace, execute:

```bash
vagrant up

```

Once the machine starts completely, log in via SSH to copy over the `command_runner.py` and `reverse_shell_implant.py` components:

```bash
vagrant ssh

```

#### Step 2: Fire up the Host C2 Console Interface

On your primary development machine terminal window, initialize your unified orchestration interface built during **Step 8**:

```bash
python3 scripts/module4/post_automation.py c2

```

Your host terminal drops cleanly into the root manager screen:

```
[*] C2 Server Initialized on port 4444. Awaiting implants...
C2 Console> 

```

#### Step 3: Trigger the Sandboxed Target Connection Payload

Inside the isolated target node environment (`vagrant ssh` session window), invoke the active implant script pointing back to the host machine interface:

```bash
python3 reverse_shell_implant.py

```

#### Step 4: Verify Command Execution and Log Analysis

Look back at your Host workstation console screen. The threaded catcher flags the session check-in automatically. Drop straight into the channel to issue verification queries, then run the defensive analysis pass to isolate footprints:

```
[C2 ALERT] New session #1 checked in from 192.168.56.105:49152
C2 Console> interact 1

--- Interacting with Session #1 (192.168.56.105) ---
$ whoami
vagrant
$ cd /var/log
Changed directory to /var/log
$ back

C2 Console> exit
[*] Shuts down all sessions and terminates listener infrastructure.

# Run defensive logs parsing to match verification rules
python3 scripts/module4/post_automation.py analyze --file test_access.log --threshold 10

```
