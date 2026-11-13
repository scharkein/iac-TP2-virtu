# TP2 - 2 noeuds Proxmox (pve01 + pve02) dans VMware Workstation
# Prerequis : vagrant, plugin vagrant-vmware-desktop, Vagrant VMware Utility
#
# IMPORTANT (idempotence apres "vagrant halt" / "vagrant up") :
#   - pas de config.vm.hostname : Vagrant remettrait "127.0.1.1 <fqdn>" dans /etc/hosts
#     a chaque demarrage, or Proxmox exige que le hostname se resolve vers l'IP du noeud.
#     Le hostname est gere par Ansible (01-install-proxmox.yml).
#   - private_network avec auto_config: false : Vagrant ne reecrit plus /etc/network/interfaces
#     a chaque demarrage (sinon eth1 est redeclare alors qu'il est le port du bridge vmbr0).
#     L'IP de gestion est posee une seule fois (provisioner "once") ; ensuite c'est
#     Ansible (vmbr0) qui en est proprietaire.
#   - ssh.host = IP de gestion, une fois la VM provisionnee : apres Proxmox (bridges
#     vmbr0/vmbr1, VLAN, pare-feu en policy_in DROP), Vagrant ne doit plus deviner l'IP de
#     la VM ni passer par le NAT (bloque par le pare-feu). Il se connecte a 192.168.56.x:22,
#     deja autorise (admin_ip) et possede par Ansible. Au tout premier "vagrant up", on
#     garde le comportement par defaut (NAT + port forward) car l'IP n'existe pas encore.
#   - boot_timeout augmente : un Proxmox imbrique demarre lentement.
#
# Au quotidien, preferer "vagrant suspend" / "vagrant resume" a "vagrant halt" / "vagrant up"
# (pas de reboot : le reseau Proxmox n'est pas touche).
Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-12"            # Debian 12 = base de Proxmox VE 8
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.boot_timeout = 600                 # Proxmox imbrique = boot lent (defaut 300 s)

  nodes = {
    "pve01" => { ip: "192.168.56.11", ram: 8192, cpus: 4 },
    "pve02" => { ip: "192.168.56.12", ram: 4096, cpus: 2 },
  }

  nodes.each do |name, n|
    config.vm.define name do |node|
      node.vm.network "private_network", ip: n[:ip], auto_config: false   # reseau de gestion / Corosync

      # SSH via l'IP de gestion (stable, geree par Ansible, autorisee par le pare-feu),
      # MAIS seulement une fois la VM provisionnee : au 1er boot cette IP n'existe pas encore
      # (c'est le provisioner "once" ci-dessous qui la pose), Vagrant doit donc utiliser
      # le NAT + port forward par defaut. Le fichier action_provision est cree par Vagrant
      # des que les provisioners ont tourne.
      provisioned = File.exist?(File.join(__dir__, ".vagrant", "machines", name, "vmware_desktop", "action_provision"))
      if provisioned
        node.ssh.host = n[:ip]
        node.ssh.port = 22          # pas de port forward 2222 sur l'IP host-only
      end

      # IP de gestion temporaire, persistante (survit au reboot noyau du playbook 01).
      # Le playbook 01 supprime ce fichier quand vmbr0 prend le relais.
      node.vm.provision "shell", run: "once", inline: <<-SH
        set -e
        mkdir -p /etc/network/interfaces.d
        grep -q '^source /etc/network/interfaces.d' /etc/network/interfaces || \\
          echo 'source /etc/network/interfaces.d/*' >> /etc/network/interfaces
        printf 'auto eth1\\niface eth1 inet static\\n    address #{n[:ip]}/24\\n' > /etc/network/interfaces.d/00-vagrant-mgmt
        ip addr replace #{n[:ip]}/24 dev eth1
        ip link set eth1 up
      SH

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