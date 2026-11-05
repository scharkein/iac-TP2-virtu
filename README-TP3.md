# TP3 Proxmox - Segmentation VLAN & filtrage multi-niveaux (Ansible)

Suite du TP2 (meme `inventory.ini`, memes `secrets.yml`). **Non teste sur votre poste** : lancez les playbooks
un par un et lisez la sortie. Prerequis : TP2 joue jusqu'au 03 (04 recommande), `db_app_password` ajoute dans `secrets.yml`.

```bash
cd ansible
ansible-playbook -e @secrets.yml 05-vlan-aware.yml   # etape 1 : vmbr0 VLAN-aware + vmbr0.99
ansible-playbook -e @secrets.yml 06-workloads.yml    # etape 2 : CT 102 (VLAN 10) + VM 101 (VLAN 20)
ansible-playbook -e @secrets.yml 07-firewall.yml     # etape 3 : routage, IPSets, Security Groups, DROP admin
ansible-playbook -e @secrets.yml 08-antispoof.yml    # etape 4 : ipfilter-net0 + macfilter (test avant/apres)
ansible-playbook -e @secrets.yml 09-audit.yml        # etape 5 : T1..T4 + extraits pve-firewall.log
ansible-playbook -e @secrets.yml 09-audit.yml --tags host-layer   # option : preuve de la regle du noeud
```
Les preuves texte (a coller dans le rapport) sont ecrites dans `reports/` (etape1-pveXX.txt ... etape5.txt).
Captures d'ecran GUI, reponses aux 12 questions et analyse commentee des logs restent a faire.

## Choix d'architecture (ecarts avec le sujet, a mentionner dans le rapport)
- **Acces admin conserve en non tague** (192.168.56.x, VMware host-only ne transporte pas le VLAN 99) : le sujet
  recommande lui-meme une IP temporaire non taguee. `vmbr0.99` (192.168.99.2 sur pve01, .3 sur pve02) existe quand meme
  et c'est la cible des tests T3/T4. Pas de gateway 192.168.99.254 (n'existe pas, casserait la route par defaut).
- **L'hote est le routeur inter-VLAN** (`vmbr0.10` = 192.168.10.1, `vmbr0.20` = 192.168.20.1, cree par 07) : sans routeur,
  le test T1 (Web -> DB 3306 = succes) est impossible. A l'etape 2 le ping Web -> DB echoue bien (pas encore de routeur).
- **Invites installes d'abord sur vmbr1** (NAT/Internet du TP2) puis bascules sur vmbr0 + tag : les VLAN n'ont pas Internet.
- IDs : VM DB = **101**, CT web = **102** (le 100 et le 200 du TP2 sont intacts).
- `admin-workstations` = `admin_ip` (192.168.56.1) ; `admin-net` du TP2 est conserve (meme contenu).
- Web et DB en `policy_out: DROP` (zero-trust). Compte SQL `app` limite a 192.168.10.10.
- 07 **remplace `cluster.fw`** du TP2 en le completant : ne relancez pas 04 apres 07.

## Points a verifier
- `pve-firewall compile` valide la syntaxe (verifie par 07). Filets : reseau = retour arriere auto en 5 min,
  pare-feu = arret auto en 10 min si l'acces 8006 est perdu.
- Le format exact des lignes de `pve-firewall.log` depend de la version : 09 affiche les lignes `SRC=192.168.10.10`.
- Depuis votre poste, pour atteindre le web : `sudo ip route add 192.168.10.0/24 via 192.168.56.11` puis `curl http://192.168.10.10`.
- Bonus +1.5 pt (script/pvesh en annexe) : mettez les playbooks en annexe et demandez au formateur s'ils comptent.
- Si un `qm create` echoue en cours de route, `qm destroy 101` / `pct destroy 102` avant de relancer 06.
