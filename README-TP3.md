# TP3 Proxmox - Segmentation VLAN & filtrage multi-niveaux (Ansible)

Suite du TP2. Les playbooks 01 a 05 restent inchanges. Le playbook 06 a ete refait :
la VM DB est provisionnee par SSH depuis le poste de controle, via `pve01` comme relais.
Le QEMU Guest Agent n'est plus necessaire pour installer MariaDB ; il est installe ensuite
pour les operations Proxmox et les etapes 08.

## Prerequis

- TP2 execute jusqu'au playbook 04 (05 du TP3 applique ensuite).
- `db_app_password` defini dans `secrets.yml`.
- Le poste de controle est Linux, WSL ou un environnement disposant d'OpenSSH et d'Ansible.
- La cle Vagrant de `pve01` est presente dans `.vagrant/machines/pve01/vmware_desktop/private_key`.

Depuis le dossier du projet :

```bash
ssh-keygen -t ed25519 -f ~/.ssh/tp3_vm
cd ansible
ansible-galaxy collection install -r requirements.yml
cp secrets.yml.example secrets.yml
# Editer secrets.yml et remplacer tous les mots de passe de demonstration.
```

## Playbooks

```bash
ansible-playbook -e @secrets.yml 05-vlan-aware.yml
ansible-playbook -e @secrets.yml 06-workloads.yml
ansible-playbook -e @secrets.yml 07-firewall.yml
ansible-playbook -e @secrets.yml 08-antispoof.yml
ansible-playbook -e @secrets.yml 09-audit.yml
ansible-playbook -e @secrets.yml 09-audit.yml --tags host-layer
```

### Reprise sans destruction d'une VM/CT deja existant

Le playbook 06 corrige maintenant la carte reseau de la VM 101 et du CT 102 en place :
le pare-feu Proxmox de l'interface est desactive pendant le bootstrap APT sur `vmbr1`,
puis active par le playbook 07 seulement apres installation des fichiers de politique
`101.fw` et `102.fw`. Cette reprise ne detruit ni le disque de la VM ni le CT existant.

L'option `tp3_recreate_db_vm=true` reste disponible uniquement pour une recreation volontaire
(apres sauvegarde), par exemple si le cloud-init ou la cle SSH injectee doivent etre remplaces :

```bash
ansible-playbook -e @secrets.yml -e tp3_recreate_db_vm=true 06-workloads.yml
```

**Attention :** cette option detruit la VM 101 et son disque. Ne l'utilise pas pour corriger
le probleme reseau courant. Les executions normales se font sans cette option.

## Architecture du playbook 06

1. VM 101 demarree sur `vmbr1`, IP temporaire `10.10.10.40`.
2. Ansible depuis le PC atteint la VM en SSH via `pve01` (ProxyCommand).
3. Ansible installe MariaDB, cree `appdb` et le compte SQL `app` autorise depuis `192.168.10.10`.
4. QEMU Guest Agent est installe et teste.
5. VM 101 bascule sur `vmbr0`, VLAN 20, IP `192.168.20.10`.
6. CT 102 est installe sur `vmbr1`, puis bascule sur `vmbr0`, VLAN 10, IP `192.168.10.10`.
7. Les interfaces des invites restent avec `firewall=0` pendant le bootstrap ; le playbook 07 installe d'abord leurs politiques `.fw`, active ensuite `firewall=1` et recharge `pve-firewall`.

Le NAT de `vmbr1` doit fonctionner pendant l'installation des paquets. Les regles MASQUERADE
sont maintenant convergees vers une seule occurrence : les templates suppriment les doublons
et le playbook 06 repare aussi la regle existante sans empiler de nouvelles copies. Si APT echoue,
verifier la connectivite DNS/Internet du reseau `10.10.10.0/24` sur `pve01`.

## Suite du TP

- `07-firewall.yml` configure le routage inter-VLAN et les regles.
- `08-antispoof.yml` utilise toujours `tp3-vmexec` pour les tests anti-usurpation via QEMU Guest Agent.
- `09-audit.yml` execute les tests T1 a T4.

Les preuves sont ecrites dans `reports/`. Captures GUI, reponses aux questions et analyse des logs
restent a completer dans le rapport.
