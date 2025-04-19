# Arch Linux Hardening - Script de Segurança Automatizado

Este script Perl aplica verificações e correções de segurança baseadas em recomendações do **Lynis**. Ele realiza hardening de kernel, autenticação, arquivos, serviços e protocolos.

---

## 🔧 Uso

```bash
perl hardening.pl <ação> [--dry-run] [--auto]
```

- --dry-run → Mostra o que seria feito, mas não altera o sistema

- --auto → Executa sem interação do usuário

## 📜 Ações disponíveis

| Ação | Descrição |
| ---- | --------- |
| boot_5264 | Verifica segurança dos serviços systemd ativos |
| krnl_5820 | Desativa core dumps pelo /etc/security/limits.conf |
| auth_9230 | Configura rounds de hashing em /etc/login.defs |
| auth_9262 | Instala módulo PAM de força de senha (pam_passwdqc) |
| auth_9282 | Define datas de expiração para senhas |
| auth_9286 | Define idade mínima/máxima de senha em /etc/login.defs |
| auth_9328 | Ajusta umask para 027 em /etc/login.defs |
| file_6354 | Lista arquivos com mais de 90 dias em /tmp |
| usb_1000 | Desabilita driver de armazenamento USB (usb-storage) |
| usb_1000_restore | Reverte desativação do USB |
| strg_1846 | Desabilita suporte a FireWire |
| name_4028 | Verifica e define domínio DNS do sistema |
| pkgs_7312 | Atualiza todos os pacotes do sistema (pacman -Syu) |
| pkgs_7320 | Instala arch-audit para detectar pacotes vulneráveis |
| netw_3200 | Desativa protocolos desnecessários: dccp, sctp, rds, tipc |
| unblock_net_protocols | Reverte bloqueio de protocolos de rede |
| ssh_7408 | Hardening completo de sshd_config |
| php_2372 | Desativa expose_php no php.ini |
| php_2376 | Desativa allow_url_fopen no php.ini |
| logg_2146 | Configura rotação de logs para arquivos não gerenciados |
| bann_7126 | Adiciona banner legal em /etc/issue e /etc/issue.net |
| acct_9622 | Ativa accton para rastrear execuções |
| acct_report | Relatório de contabilidade de processos (sa, lastcomm) |
| acct_9626 | Ativa coleta de estatísticas com sysstat (sar, etc) |
| acct_9628 | Ativa auditd com regras básicas (/etc/audit/rules.d) |
| audit_report | Relatório do auditd com análise do /var/log/audit/audit.log |
| time_3104 | Ativa sincronização de tempo com systemd-timesyncd |
| cryp_7902 | Verifica expiração de certificados (*.crt, *.pem, etc) |
| fint_4350 | Instala e inicializa AIDE |
| fint_schedule | Agenda verificações do AIDE via cron ou systemd timer |
| tool_5002 | Verifica presença de ferramentas como Ansible, Puppet, etc. |
| file_7524 | Verifica permissões inseguras e corrige com chmod |
| krnl_6000 | Aplica sysctl seguro e salva backup |
| krnl_6000_restore | Restaura sysctl anterior de backup |
| hrdn_7222 | Verifica permissões e donos de compiladores |
| hrdn_7222_prune | Remove compiladores órfãos ou fora da whitelist |
| hrdn_7230 | Instala rkhunter, executa verificação inicial e agenda escaneamento | 


