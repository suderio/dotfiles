#!/usr/bin/env perl
use strict;
use warnings;

# Restaura os valores anteriores de sysctl a partir de um backup salvo
sub krnl_6000_restore {
    use File::Basename;
    use File::Glob qw(bsd_glob);
    use POSIX qw(strftime);

    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $backup_dir = '/var/backups';
    my @backups = sort { $b cmp $a } bsd_glob("$backup_dir/sysctl-backup-*.conf");

    if (!@backups) {
        print "❌ Nenhum backup encontrado em $backup_dir.\n";
        return;
    }

    my $latest = $backups[0];
    print "[KRNL-6000] Usando backup mais recente: $latest\n";

    open my $in, '<', $latest or die "Erro ao abrir backup: $!";
    my @lines = grep { /^\s*[\w\.]+\s*=\s*\S+/ } <$in>;
    close $in;

    my @restored;
    foreach my $line (@lines) {
        $line =~ s/^\s+|\s+$//g;
        my ($key, $val) = split /\s*=\s*/, $line, 2;

        if ($dry_run) {
            print "🔍 sysctl -w $key=$val (simulado)\n";
        } else {
            my $result = system("sysctl -w $key=$val");
            if ($result == 0) {
                print "✅ Restaurado: $key = $val\n";
                push @restored, [$key, $val];
            } else {
                print "❌ Falha ao aplicar $key = $val\n";
            }
        }
    }

    if (!$dry_run && @restored) {
        print "\n✅ Restauração concluída a partir de $latest\n";
    } elsif ($dry_run) {
        print "\n🔍 Simulação concluída. Nenhuma alteração aplicada.\n";
    }
}

# Configura verificação periódica do AIDE via cron ou systemd timer
sub fint_schedule {
    print "[FINT] Deseja configurar execução periódica do AIDE?\n";
    print "Escolha o método:\n";
    print "  1) Cron diário (/etc/cron.daily)\n";
    print "  2) systemd timer (diário)\n";
    print "Selecione [1/2]: ";
    chomp(my $choice = <STDIN>);

    if ($choice eq '1') {
        my $cron_path = '/etc/cron.daily/aide-check';
        print "📝 Criando tarefa de verificação diária em $cron_path...\n";

        open my $out, '>', $cron_path or die "Erro ao criar $cron_path: $!";
        print $out <<"EOF";
#!/bin/bash
/usr/bin/aide --check > /var/log/aide-check.log 2>&1
EOF
        close $out;
        system("chmod +x $cron_path");
        print "✅ Verificação diária via cron configurada com sucesso.\n";

    } elsif ($choice eq '2') {
        print "⚙️  Criando serviço e timer systemd...\n";

        my $unit = '/etc/systemd/system/aide-check.service';
        my $timer = '/etc/systemd/system/aide-check.timer';

        open my $s, '>', $unit or die "Erro ao criar $unit: $!";
        print $s <<"EOF";
[Unit]
Description=AIDE File Integrity Check

[Service]
Type=oneshot
ExecStart=/usr/bin/aide --check
StandardOutput=append:/var/log/aide-check.log
StandardError=append:/var/log/aide-check.log
EOF
        close $s;

        open my $t, '>', $timer or die "Erro ao criar $timer: $!";
        print $t <<"EOF";
[Unit]
Description=Daily AIDE integrity check

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
        close $t;

        system("systemctl daemon-reexec");
        system("systemctl daemon-reload");
        system("systemctl enable --now aide-check.timer");

        print "✅ Verificação diária configurada via systemd timer.\n";
    } else {
        print "❌ Opção inválida. Nenhuma ação realizada.\n";
    }
}

# Exibe relatório simplificado de auditoria com base em /var/log/audit/audit.log
sub audit_report {
    my $log = '/var/log/audit/audit.log';

    print "[AUDIT] Gerando relatório baseado em $log...\n";

    unless (-f $log) {
        print "❌ Arquivo $log não encontrado. auditd está ativado?\n";
        return;
    }

    print "\n📌 Tipos de eventos registrados:\n";
    system("grep '^type=' $log | cut -d ' ' -f1 | sort | uniq -c | sort -nr | head");

    print "\n🔍 Últimos comandos executados (execve):\n";
    system("grep 'execve' $log | tail -n 10");

    print "\n🔐 Acessos a arquivos sensíveis (/etc/passwd, /etc/shadow, /etc/sudoers):\n";
    system("grep -Ei '/etc/passwd|/etc/shadow|/etc/sudoers' $log | tail -n 10");

    print "\n🛠️  Uso de comandos críticos (sudo, passwd, chmod, chown):\n";
    system("grep -Ei 'sudo|passwd|chmod|chown' $log | tail -n 10");
}

# Exibe relatórios com base nos dados do process accounting
sub acct_report {
    my $logfile = '/var/log/pacct';

    print "[ACCT] Gerando relatórios de auditoria do process accounting...\n";

    unless (-f $logfile) {
        print "❌ Arquivo $logfile não encontrado. O accounting está ativado?\n";
        return;
    }

    print "\n📄 Comandos executados recentemente:\n";
    system("lastcomm | head -n 20");

    print "\n👤 Resumo por usuário (uso de comandos):\n";
    system("lastcomm | awk '{print \$1}' | sort | uniq -c | sort -nr | head");

    print "\n🧾 Estatísticas por comando (tempo total de CPU):\n";
    system("sa -m | head");

    print "\n📆 Estatísticas por usuário:\n";
    system("sa -u | head");
}

# Reverte bloqueio de protocolos configurado por netw_3200
sub unblock_net_protocols {
    my $conf_file = '/etc/modprobe.d/block-protocols.conf';
    my @protocols = qw(dccp sctp rds tipc);

    print "[NETW-3200] Revertendo bloqueios de protocolos de rede...\n";

    unless (-f $conf_file) {
        print "ℹ️  Arquivo $conf_file não existe. Nada a reverter.\n";
        return;
    }

    open my $in, '<', $conf_file or die "Erro ao ler $conf_file: $!";
    my @lines = <$in>;
    close $in;

    # Filtra todas as linhas exceto os installs dos protocolos bloqueados
    my @filtered = grep {
        my $line = $_;
        !grep { $line =~ /^\s*install\s+\Q$_\E\s+/ } @protocols;
    } @lines;

    open my $out, '>', $conf_file or die "Erro ao escrever $conf_file: $!";
    print $out @filtered;
    close $out;

    print "✅ Entradas de bloqueio removidas de $conf_file.\n";

    print "Deseja recarregar os módulos dos protocolos desbloqueados agora? [s/N] ";
    chomp(my $resposta = <STDIN>);
    if (lc($resposta) eq 's') {
        foreach my $mod (@protocols) {
            system("sudo modprobe $mod") == 0
                ? print "✅ Módulo $mod carregado.\n"
                : print "⚠️  Não foi possível carregar $mod (pode ser normal).\n";
        }
    } else {
        print "🔄 Nenhum módulo recarregado.\n";
    }
}

# Reverte a blacklist de módulos FireWire criada por strg_1846
sub unblock_firewire_modules {
    my $conf_file = '/etc/modprobe.d/firewire.conf';
    my @modules = qw(firewire-core firewire-ohci firewire-sbp2);

    print "[STRG-1846] Revertendo bloqueio de módulos FireWire...\n";

    unless (-f $conf_file) {
        print "ℹ️  Arquivo $conf_file não existe. Nada a fazer.\n";
        return;
    }

    open my $in, '<', $conf_file or die "Erro ao ler $conf_file: $!";
    my @lines = <$in>;
    close $in;

    my @filtered = grep {
        my $line = $_;
        !grep { $line =~ /^\s*blacklist\s+\Q$_\E\b/ } @modules;
    } @lines;

    if (@filtered == @lines) {
        print "✔️  Nenhuma entrada de blacklist FireWire encontrada. Nada a remover.\n";
    } else {
        open my $out, '>', $conf_file or die "Erro ao escrever em $conf_file: $!";
        print $out @filtered;
        close $out;
        print "✅ Entradas de blacklist FireWire removidas de $conf_file.\n";
    }

    print "Deseja recarregar os módulos FireWire? [s/N] ";
    chomp(my $resp = <STDIN>);
    if (lc($resp) eq 's') {
        foreach my $mod (@modules) {
            system("sudo modprobe $mod") == 0
                ? print "✅ Módulo $mod carregado.\n"
                : print "⚠️  Não foi possível carregar $mod (pode ser normal).\n";
        }
    } else {
        print "🔄 Nenhum módulo FireWire foi recarregado.\n";
    }
}

# Reverte a configuração feita por usb_1000
sub unblock_usb_storage {
    my $conf_file = '/etc/modprobe.d/usb-storage.conf';

    print "[USB-1000] Revertendo bloqueio do módulo usb-storage...\n";

    unless (-f $conf_file) {
        print "ℹ️  Arquivo $conf_file não existe. Nada a fazer.\n";
        return;
    }

    open my $in, '<', $conf_file or die "Erro ao ler $conf_file: $!";
    my @lines = <$in>;
    close $in;

    my @filtered = grep { !/^\s*blacklist\s+usb-storage\b/ } @lines;

    if (@filtered == @lines) {
        print "✔️  Nenhuma linha de blacklist encontrada em $conf_file.\n";
        return;
    }

    open my $out, '>', $conf_file or die "Erro ao escrever em $conf_file: $!";
    print $out @filtered;
    close $out;

    print "✅ Linha de bloqueio removida de $conf_file.\n";

    print "Deseja carregar novamente o módulo usb-storage? [s/N] ";
    chomp(my $resp = <STDIN>);
    if (lc($resp) eq 's') {
        system("sudo modprobe usb-storage") == 0
            ? print "✅ Módulo usb-storage carregado com sucesso.\n"
            : print "❌ Falha ao carregar módulo usb-storage.\n";
    } else {
        print "🔄 Módulo não foi recarregado.\n";
    }
}

