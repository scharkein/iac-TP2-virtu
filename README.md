# TP2 Proxmox VE - environnement automatise (Vagrant + Ansible)

Cree 2 noeuds Proxmox VE 8 (pve01 + pve02) dans VMware Workstation, puis applique les etapes du TP,
bonus cluster compris. **Non teste sur votre poste : lisez "Points a verifier".**

## Prerequis (hote Debian 13)
- Vagrant, plugin `vagrant plugin install vagrant-vmware-desktop`, paquet *Vagrant VMware Utility*
- `sudo apt install ansible`
- `cp ansible/secrets.yml.example ansible/secrets.yml` puis choisir 3 mots de passe (12+ caracteres)

## Lancement
```bash
vagrant up                                   # cree pve01 et pve02 (Debian 12, virtualisation imbriquee)
cd ansible
ansible-playbook -e @secrets.yml 01-install-proxmox.yml   # etape 1 : Proxmox VE 8 (+ reseau, 2 redemarrages)
ansible-playbook -e @secrets.yml 02-config-cluster.yml    # etape 2 + BONUS cluster + RBAC (etape 4A)
ansible-playbook -e @secrets.yml 03-guests-backup.yml     # etape 3 + tache de sauvegarde (etape 5)
# --> faire la MFA a la main (ci-dessous), puis :
ansible-playbook -e @secrets.yml 04-hardening.yml         # etape 4C : pare-feu 3 niveaux
```
A la demande : `--tags snapshot` (snapshot `avant-modif`) et `--tags backup-now` (vzdump manuel) sur le playbook 03.

## Ce qui reste volontairement manuel
- **MFA TOTP de root@pam et operateur@pve** (etape 4B) : indispensable a la main, root sans MFA = 0 sur le durcissement.
- Rollback du snapshot, captures d'ecran, test de blocage (`nmap -Pn -p 22,8006 <IP>` depuis un poste hors admin-net).
- La soutenance porte sur toutes les etapes pour chaque membre : manipulez la web-UI au moins une fois chacun.

## Ecarts avec le sujet (a mentionner dans le rapport)
- Proxmox est installe sur Debian 12 (methode officielle) et non avec l'ISO Proxmox.
- Disques des invites sur `local` (repertoire) au lieu de `local-lvm` : pas de disque LVM dans la box.
- Invites sur `vmbr1` (reseau 10.10.x.0/24 NAT) et non `vmbr0`, pour avoir Internet sans bridge VMware.
- VM 100 deployee depuis l'image cloud Debian 12 (pas d'installation manuelle de l'OS).
- Le noeud pve02 a 4 Go de RAM (8 Go sur pve01, 16 Go sur l'hote).

## Points a verifier
- `admin_ip` (group_vars/all.yml) = IP de l'hote sur le reseau 192.168.56.0/24 (`ip -4 a`). Sinon le pare-feu vous coupe l'acces.
- Noms/provider : box `bento/debian-12` avec le provider `vmware_desktop`.
- Apres le playbook 04, `vagrant ssh` ne marche plus (normal) : `ssh -i .vagrant/machines/pve01/vmware_desktop/private_key vagrant@192.168.56.11`.
- Filet de securite : si vous perdez l'acces, le pare-feu s'arrete seul apres 10 minutes.
