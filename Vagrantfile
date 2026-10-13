# TP2 - 2 noeuds Proxmox (pve01 + pve02) dans VMware Workstation
# Prerequis : vagrant, plugin vagrant-vmware-desktop, Vagrant VMware Utility
Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-12"            # Debian 12 = base de Proxmox VE 8
  config.vm.synced_folder ".", "/vagrant", disabled: true

  nodes = {
    "pve01" => { ip: "192.168.56.11", ram: 8192, cpus: 4 },
    "pve02" => { ip: "192.168.56.12", ram: 4096, cpus: 2 },
  }

  nodes.each do |name, n|
    config.vm.define name do |node|
      node.vm.hostname = "#{name}.lab.local"
      node.vm.network "private_network", ip: n[:ip]   # reseau de gestion / Corosync
      node.vm.provider "vmware_desktop" do |v|
        v.gui = false
        v.vmx["displayname"] = name
        v.vmx["memsize"]     = n[:ram].to_s
        v.vmx["numvcpus"]    = n[:cpus].to_s
        v.vmx["vhv.enable"]  = "TRUE"                 # virtualisation imbriquee (AMD-V/RVI)
      end
    end
  end
end
