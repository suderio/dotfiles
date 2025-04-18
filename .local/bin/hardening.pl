#!/usr/bin/env perl
use strict;
use warnings;

# Reference: https://cisofy.com/lynis/controls/<CODE-NNNN>/

# BOOT-5264: Consider hardening system services
# Run '/usr/bin/systemd-analyze security SERVICE' for each service

sub boot_5264 {
    print "[BOOT-5264] Verificando o nível de segurança dos serviços systemd...\n";

    # Lista todos os serviços ativos
    my @services = `systemctl list-units --type=service --state=running --no-legend`;
    chomp @services;

    foreach my $line (@services) {
        my ($service) = split /\s+/, $line;
        next unless defined $service && $service =~ /\.service\$/;

        print "\n🔍 Analisando segurança de $service:\n";
        my $output = `systemd-analyze security $service 2>&1`;
        print "$output\n";
    }

    print "\n[BOOT-5264] Análise concluída. Revise os serviços com baixa pontuação e ajuste seus arquivos unitários.\n";
}

# KRNL-5820: Disable core dumps via limits.conf
# https://linux-audit.com/software/understand-and-configure-core-dumps-work-on-linux/

sub krnl_5820 {
    my $file = '/etc/security/limits.conf';
    my $marker = '# Added by krnl_5820 hardening script';
    my $line1 = '*               hard    core            0';
    my $line2 = 'root            hard    core            0';

    print "[KRNL-5820] Desativando core dumps em $file...\n";

    open my $in, '<', $file or die "Erro ao ler $file: $!";
    my @lines = <$in>;
    close $in;

    if (grep { /\Q$line1\E/ } @lines && grep { /\Q$line2\E/ } @lines) {
        print "✔️  Core dumps já desabilitados. Nenhuma ação necessária.\n";
        return;
    }

    open my $out, '>>', $file or die "Erro ao escrever em $file: $!";
    print $out "\n$marker\n$line1\n$line2\n";
    close $out;

    print "✅ Core dumps desativados com sucesso.\n";
}

# AUTH-9262: Install a PAM module for password strength testing
sub auth_9262 {
    my $pkg = 'libpam-passwdqc';
    my $pam_file = '/etc/pam.d/passwd';
    my $marker = '# Added by auth_9262 hardening script';
    my $pam_line = 'password    requisite     pam_passwdqc.so';

    print "[AUTH-9262] Verificando módulo PAM de força de senha...
";

    my $is_installed = system("pacman -Q $pkg > /dev/null 2>&1") == 0;

    unless ($is_installed) {
        print "📦 Instalando $pkg...
";
        system("sudo pacman -Sy --noconfirm $pkg") == 0
            or die "❌ Falha ao instalar $pkg
";
    }

    open my $in, '<', $pam_file or die "Erro ao ler $pam_file: $!";
    my @lines = <$in>;
    close $in;

    if (grep { /pam_passwdqc\.so/ } @lines) {
        print "✔️  pam_passwdqc já está configurado em $pam_file.
";
        return;
    }

    open my $out, '>>', $pam_file or die "Erro ao escrever em $pam_file: $!";
    print $out "
$marker
$pam_line
";
    close $out;

    print "✅ pam_passwdqc ativado em $pam_file.
";
}

# AUTH-9282: Set password expiration dates for accounts
sub auth_9282 {
    print "[AUTH-9282] Verificando contas sem expiração de senha...
";

    open my $pw, '-|', 'getent shadow' or die "Erro ao executar getent: $!";
    while (<$pw>) {
        my ($user, $pass, undef, undef, $expire) = split /:/;
        next if $pass =~ /^[*!]/;  # ignora contas sem senha ou travadas

        if (!defined $expire || $expire eq '' || $expire == 99999) {
            print "⚠️  Usuário '$user' não tem expiração definida. Corrigindo...
";
            system("sudo chage -M 90 $user");
        }
    }
    close $pw;

    print "✅ Expiração de senha configurada para contas aplicáveis.
";
}

# AUTH-9286: Configure min/max password age in /etc/login.defs
sub auth_9286 {
    my $file = '/etc/login.defs';
    my $min_line = 'PASS_MIN_DAYS   1';
    my $max_line = 'PASS_MAX_DAYS   90';

    print "[AUTH-9286] Verificando política de idade mínima/máxima de senha em $file...\n";

    open my $in, '<', $file or die "Erro ao ler $file: $!";
    my @lines = <$in>;
    close $in;

    my $found_min = 0;
    my $found_max = 0;
    my $modified = 0;

    for (@lines) {
        if (/^\s*PASS_MIN_DAYS\s+/) {
            $_ = "$min_line\n";
            $found_min = 1;
            $modified = 1;
        }
        if (/^\s*PASS_MAX_DAYS\s+/) {
            $_ = "$max_line\n";
            $found_max = 1;
            $modified = 1;
        }
    }

    unless ($found_min) {
        push @lines, "$min_line\n";
        $modified = 1;
    }
    unless ($found_max) {
        push @lines, "$max_line\n";
        $modified = 1;
    }

    if ($modified) {
        open my $out, '>', $file or die "Erro ao escrever em $file: $!";
        print $out @lines;
        close $out;
        print "✅ Política de idade de senha aplicada (min: 1 dia, max: 90 dias).\n";
    } else {
        print "✔️  Política de idade de senha já configurada corretamente.\n";
    }
}

# AUTH-9230: Configure password hashing rounds in /etc/login.defs
# https://linux-audit.com/authentication/configure-the-minimum-password-length-on-linux-systems/

sub auth_9230 {
    my $file = '/etc/login.defs';
    my $marker = '# Added by auth_9230 hardening script';
    my $rounds_line = 'SHA_CRYPT_ROUNDS 65536';

    print "[AUTH-9230] Verificando/ajustando rounds de hash de senha em $file...\n";

    open my $in, '<', $file or die "Erro ao ler $file: $!";
    my @lines = <$in>;
    close $in;

    my $modified = 0;
    my $found = 0;

    for (@lines) {
        if (/^\s*SHA_CRYPT_ROUNDS\s+/) {
            $_ = "$rounds_line\n";
            $found = 1;
            $modified = 1;
        }
    }

    if (!$found) {
        push @lines, "$marker\n$rounds_line\n";
        $modified = 1;
    }

    if ($modified) {
        open my $out, '>', $file or die "Erro ao escrever em $file: $!";
        print $out @lines;
        close $out;
        print "✅ SHA_CRYPT_ROUNDS ajustado para 65536.\n";
    } else {
        print "✔️  SHA_CRYPT_ROUNDS já está configurado corretamente.\n";
    }
}


# Executar função diretamente se o script for chamado isoladamente

if (!caller) {
    my $action = shift @ARGV // '';

    if ($action eq 'boot_5264') {
        boot_5264();
    } elsif ($action eq 'krnl_5820') {
        krnl_5820();
    } elsif ($action eq 'auth_9230') {
        auth_9230();
    } elsif ($action eq 'auth_9262') {
        auth_9262();
    } elsif ($action eq 'auth_9282') {
        auth_9282();
    } else {
        print "Uso: $0 [boot_5264 | krnl_5820 | auth_9230 | auth_9262 | auth_9282]
";
    }
} elsif ($action eq 'krnl_5820') {
        krnl_5820();
    } elsif ($action eq 'auth_9230') {
        auth_9230();
    } else {
        print "Uso: $0 [boot_5264 | krnl_5820 | auth_9230]
";
    }
}

# AUTH-9328: Enforce umask 027 in /etc/login.defs
sub auth_9328 {
    my $file = '/etc/login.defs';
    my $target = 'UMASK 027';

    print "[AUTH-9328] Verificando configuração de umask padrão em $file...\n";

    open my $in, '<', $file or die "Erro ao ler $file: $!";
    my @lines = <$in>;
    close $in;

    my $found = 0;
    my $modified = 0;

    for (@lines) {
        if (/^\s*UMASK\s+/) {
            $_ = "$target\n";
            $found = 1;
            $modified = 1;
        }
    }

    unless ($found) {
        push @lines, "$target\n";
        $modified = 1;
    }

    if ($modified) {
        open my $out, '>', $file or die "Erro ao escrever em $file: $!";
        print $out @lines;
        close $out;
        print "✅ umask padrão ajustado para 027 em $file.\n";
    } else {
        print "✔️  umask padrão já está configurado como 027.\n";
    }
}

# FILE-6354: Check and optionally delete files in /tmp older than 90 days
sub file_6354 {
    print "[FILE-6354] Verificando arquivos em /tmp com mais de 90 dias...\n";

    my @old_files = `find /tmp -type f -mtime +90 2>/dev/null`;
    chomp @old_files;

    if (!@old_files) {
        print "✅ Nenhum arquivo antigo encontrado em /tmp.\n";
        return;
    }

    print "⚠️  Encontrados ", scalar(@old_files), " arquivo(s) com mais de 90 dias:\n";
    foreach my $f (@old_files) {
        print "   - $f\n";
    }

    print "\nDeseja remover todos os arquivos listados acima? [s/N] ";
    chomp(my $resposta = <STDIN>);
    if (lc($resposta) eq 's') {
        my $deleted = 0;
        foreach my $f (@old_files) {
            if (-f $f) {
                unlink $f and $deleted++;
            }
        }
        print "🧹 $deleted arquivo(s) removido(s) com sucesso.\n";
    } else {
        print "❎ Nenhum arquivo foi removido.\n";
    }
}

# USB-1000: Disable USB storage module if not in use
sub usb_1000 {
    my $conf_file = '/etc/modprobe.d/usb-storage.conf';
    my $line = 'blacklist usb-storage';

    print "[USB-1000] Verificando bloqueio do módulo usb-storage...\n";

    if (-f $conf_file) {
        open my $in, '<', $conf_file or die "Erro ao ler $conf_file: $!";
        while (<$in>) {
            if (/^\s*blacklist\s+usb-storage\b/) {
                print "✔️  usb-storage já está bloqueado em $conf_file.\n";
                return;
            }
        }
        close $in;
    }

    # Se não estava presente, adiciona
    open my $out, '>>', $conf_file or die "Erro ao escrever em $conf_file: $!";
    print $out "$line\n";
    close $out;

    print "✅ usb-storage bloqueado com sucesso em $conf_file.\n";

    # Verifica se o módulo está carregado agora
    my $loaded = `lsmod | grep ^usb_storage`;
    if ($loaded) {
        print "⚠️  O módulo usb_storage está carregado atualmente. Deseja descarregá-lo agora? [s/N] ";
        chomp(my $resp = <STDIN>);
        if (lc($resp) eq 's') {
            system("sudo modprobe -r usb-storage") == 0
                ? print "🧹 Módulo usb-storage descarregado com sucesso.\n"
                : print "❌ Falha ao descarregar o módulo usb-storage.\n";
        } else {
            print "🔐 Atenção: o módulo ainda está ativo até o próximo reboot.\n";
        }
    } else {
        print "✅ Módulo usb-storage não está carregado no momento.\n";
    }
}

# STRG-1846: Disable FireWire storage drivers if not in use
sub strg_1846 {
    my $conf_file = '/etc/modprobe.d/firewire.conf';
    my @modules = qw(firewire-core firewire-ohci firewire-sbp2);
    my @blacklist_lines = map { "blacklist $_" } @modules;

    print "[STRG-1846] Verificando bloqueio de módulos FireWire...\n";

    my %already_blacklisted;
    if (-f $conf_file) {
        open my $in, '<', $conf_file or die "Erro ao ler $conf_file: $!";
        while (<$in>) {
            foreach my $mod (@modules) {
                $already_blacklisted{$mod} = 1 if /^\s*blacklist\s+\Q$mod\E\b/;
            }
        }
        close $in;
    }

    open my $out, '>>', $conf_file or die "Erro ao escrever em $conf_file: $!";
    foreach my $mod (@modules) {
        unless ($already_blacklisted{$mod}) {
            print $out "blacklist $mod\n";
            print "✅ Módulo $mod bloqueado.\n";
        }
    }
    close $out;

    print "✔️  Todos os módulos FireWire relevantes estão agora bloqueados via $conf_file.\n";

    # Verificar se estão carregados
    my $loaded = `lsmod | grep firewire`;
    if ($loaded) {
        print "⚠️  Um ou mais módulos firewire estão carregados. Deseja descarregá-los agora? [s/N] ";
        chomp(my $resposta = <STDIN>);
        if (lc($resposta) eq 's') {
            foreach my $mod (@modules) {
                system("sudo modprobe -r $mod");
            }
            print "🧹 Módulos FireWire descarregados (se estavam carregados).\n";
        } else {
            print "🔒 Os módulos permanecerão carregados até o reboot.\n";
        }
    } else {
        print "✅ Nenhum módulo FireWire ativo no momento.\n";
    }
}

# NAME-4028: Verifica e corrige a configuração do nome DNS (FQDN)
sub name_4028 {
    print "[NAME-4028] Verificando configuração de nome DNS (FQDN)...\n";

    my $hostname = `hostname`;
    chomp $hostname;

    my $fqdn = `hostname --fqdn 2>/dev/null`;
    chomp $fqdn;

    my $domain = `dnsdomainname 2>/dev/null`;
    chomp $domain;

    print "📛 hostname: $hostname\n";
    print "🌐 FQDN:     $fqdn\n";
    print "🌍 domínio:  $domain\n";

    my $has_problem = (!$fqdn || $fqdn eq $hostname || $fqdn !~ /\./ || $domain eq '(none)' || $domain eq '');

    if (!$has_problem) {
        print "✅ Nome de domínio DNS configurado corretamente.\n";
        return;
    }

    print "⚠️  FQDN ou domínio DNS ausente ou incorreto.\n";
    print "🔧 Você pode corrigir isso agora.\n";
    print "Deseja configurar um FQDN agora? [s/N] ";
    chomp(my $resposta = <STDIN>);

    if (lc($resposta) ne 's') {
        print "❎ Nenhuma alteração realizada.\n";
        return;
    }

    print "Digite o FQDN desejado (ex: servidor1.exemplo.com): ";
    chomp(my $novo_fqdn = <STDIN>);
    return unless $novo_fqdn =~ /^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

    my ($novo_host, $novo_domain) = split(/\./, $novo_fqdn, 2);

    # Atualiza /etc/hostname
    open my $hostf, '>', '/etc/hostname' or die "Erro ao escrever /etc/hostname: $!";
    print $hostf "$novo_host\n";
    close $hostf;

    # Atualiza /etc/hosts
    my $hosts_file = '/etc/hosts';
    open my $in, '<', $hosts_file or die "Erro ao ler $hosts_file: $!";
    my @lines = <$in>;
    close $in;

    # Remove linha anterior 127.0.1.1 se houver
    @lines = grep { !/^127\\.0\\.1\\.1\\s+/ } @lines;
    push @lines, "127.0.1.1\t$novo_fqdn $novo_host\n";

    open my $out, '>', $hosts_file or die "Erro ao escrever $hosts_file: $!";
    print $out @lines;
    close $out;

    # Aplica com hostnamectl
    system("hostnamectl set-hostname $novo_fqdn") == 0
        ? print "✅ FQDN configurado com sucesso: $novo_fqdn\n"
        : print "❌ Erro ao aplicar hostname com hostnamectl.\n";
}

# PKGS-7312: Atualizar sistema rolling release (ex: Arch Linux)
sub pkgs_7312 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'    } @ARGV;

    print "[PKGS-7312] Verificando atualizações do sistema...\n";

    my @updates = `checkupdates 2>/dev/null`;

    if (!@updates) {
        print "✅ Sistema já está atualizado.\n";
        return;
    }

    print "📦 Encontradas ", scalar(@updates), " atualização(ões) disponíveis:\n";
    foreach my $pkg (@updates) {
        print "   - $pkg";
    }

    if ($dry_run) {
        print "🔍 Modo simulação: atualizações não serão aplicadas.\n";
        return;
    }

    if ($auto) {
        print "⚙️  Aplicando atualizações automaticamente...\n";
        system("sudo pacman -Syu");
        return;
    }

    print "\nDeseja aplicar as atualizações agora com 'sudo pacman -Syu'? [s/N] ";
    chomp(my $resposta = <STDIN>);

    if (lc($resposta) eq 's') {
        print "⏳ Atualizando sistema...\n";
        system("sudo pacman -Syu");
    } else {
        print "🔕 Atualizações não aplicadas.\n";
    }
}

# PKGS-7320: Instalar e rodar arch-audit para encontrar pacotes vulneráveis
sub pkgs_7320 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'    } @ARGV;

    print "[PKGS-7320] Verificando utilitário arch-audit...\n";

    my $installed = system("command -v arch-audit > /dev/null 2>&1") == 0;

    if (!$installed) {
        if ($dry_run) {
            print "🔍 Modo simulação: arch-audit não está instalado.\n";
            return;
        }

        if ($auto) {
            print "⚙️  Instalando arch-audit automaticamente...\n";
            system("sudo pacman -Sy --noconfirm arch-audit") == 0
                or die "❌ Falha ao instalar arch-audit.\n";
        } else {
            print "❗ O utilitário 'arch-audit' não está instalado.\nDeseja instalá-lo agora? [s/N] ";
            chomp(my $resp = <STDIN>);
            if (lc($resp) eq 's') {
                system("sudo pacman -Sy arch-audit");
            } else {
                print "⏭️  Instalação de arch-audit ignorada.\n";
                return;
            }
        }
    }

    print "🔎 Executando análise com arch-audit...\n";
    system("arch-audit");
}

# NETW-3200: Verifica e desabilita protocolos de rede não utilizados (dccp, sctp, rds, tipc)
sub netw_3200 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'    } @ARGV;

    my @protocols = qw(dccp sctp rds tipc);
    my $conf_file = '/etc/modprobe.d/block-protocols.conf';

    print "[NETW-3200] Verificando protocolos desnecessários: @protocols\n";

    my %carregados;
    my $lsmod = `lsmod`;
    foreach my $proto (@protocols) {
        $carregados{$proto} = ($lsmod =~ /^$proto\\b/m);
    }

    my $modificado = 0;

    unless (-f $conf_file) {
        open my $out, '>', $conf_file or die "Erro ao criar $conf_file: $!";
        print $out "# Criado por hardening NETW-3200\n";
        close $out;
    }

    # Lê linhas existentes para evitar duplicatas
    open my $in, '<', $conf_file or die "Erro ao ler $conf_file: $!";
    my @lines = <$in>;
    close $in;

    foreach my $proto (@protocols) {
        my $line = "install $proto /bin/true\n";
        unless (grep { /^\s*install\s+$proto\s+/ } @lines) {
            if (!$dry_run) {
                open my $out, '>>', $conf_file or die "Erro ao escrever $conf_file: $!";
                print $out $line;
                close $out;
            }
            print "✅ Adicionando blacklist para $proto em $conf_file\n";
            $modificado++;
        } else {
            print "✔️  $proto já está bloqueado em $conf_file\n";
        }

        if ($carregados{$proto}) {
            if ($dry_run) {
                print "🛑 $proto está carregado (simulação de remoção).\n";
            } elsif ($auto) {
                print "⚙️  Removendo módulo $proto automaticamente...\n";
                system("sudo modprobe -r $proto");
            } else {
                print "⚠️  Módulo $proto está carregado. Deseja descarregá-lo agora? [s/N] ";
                chomp(my $resp = <STDIN>);
                if (lc($resp) eq 's') {
                    system("sudo modprobe -r $proto");
                } else {
                    print "⏭️  $proto permanecerá carregado até reboot.\n";
                }
            }
        } else {
            print "🔒 Módulo $proto não está carregado.\n";
        }
    }

    print "✅ Proteções aplicadas para protocolos desnecessários.\n" if $modificado;

    print "\n🧪 Verificando se os bloqueios são persistentes via modprobe config...\n";
    my $config = `modprobe --showconfig 2>/dev/null`;
    foreach my $proto (@protocols) {
        if ($config =~ /^install\s+$proto\s+\/bin\/true/m) {
            print "🔒 $proto está corretamente bloqueado no modprobe config.\n";
        } else {
            print "⚠️  $proto não está persistentemente bloqueado. Verifique o conteúdo de $conf_file.\n";
        }
    }

}

# SSH-7408: Harden SSH configuration
sub ssh_7408 {
    my $config_file = '/etc/ssh/sshd_config';
    my $backup_file = '/etc/ssh/sshd_config.bak';
    my $dry_run     = grep { $_ eq '--dry-run' } @ARGV;
    my $auto        = grep { $_ eq '--auto'    } @ARGV;

    print "[SSH-7408] Endurecendo configurações de SSH em $config_file...\n";

    unless (-f $config_file) {
        print "❌ Arquivo $config_file não encontrado.\n";
        return;
    }

    # Cria backup
    if (!$dry_run && !$auto) {
        print "Deseja criar um backup de $config_file? [S/n] ";
        chomp(my $resp = <STDIN>);
        if (lc($resp) ne 'n') {
            system("cp $config_file $backup_file") == 0
                ? print "📦 Backup criado em $backup_file\n"
                : print "⚠️  Falha ao criar backup.\n";
        }
    }

    my %desired = (
        'AllowTcpForwarding'   => 'no',
        'ClientAliveCountMax'  => '2',
        'LogLevel'             => 'VERBOSE',
        'MaxAuthTries'         => '3',
        'MaxSessions'          => '2',
        'TCPKeepAlive'         => 'no',
        'X11Forwarding'        => 'no',
        'AllowAgentForwarding' => 'no',
    );

    print "Deseja alterar a porta padrão 22? [s/N] ";
    my $port_line = '';
    if (!$dry_run && (!$auto || grep { $_ =~ /^--port=/ } @ARGV)) {
        my $new_port = '';
        if ($auto) {
            ($new_port) = map { /^--port=(\\d+)/ ? $1 : () } @ARGV;
        } else {
            chomp(my $resp = <STDIN>);
            if (lc($resp) eq 's') {
                print "Digite a nova porta desejada (ex: 2222): ";
                chomp($new_port = <STDIN>);
            }
        }
        if ($new_port && $new_port =~ /^\\d+$/) {
            $desired{'Port'} = $new_port;
            $port_line = "Port $new_port\n";
        }
    }

    open my $in, '<', $config_file or die "Erro ao abrir $config_file: $!";
    my @lines = <$in>;
    close $in;

    my %found;
    for (@lines) {
        foreach my $key (keys %desired) {
            if (/^\\s*$key\\b/) {
                $_ = \"$key $desired{$key}\\n\";
                $found{$key} = 1;
            }
        }
    }

    # Adiciona os que não foram encontrados
    foreach my $key (keys %desired) {
        next if $found{$key};
        push @lines, \"$key $desired{$key}\\n\";
    }

    if ($port_line) {
        @lines = grep { !/^\\s*Port\\b/ } @lines;
        push @lines, $port_line unless $port_line eq '';
    }

    if ($dry_run) {
        print \"🔍 Modo simulação: mudanças seriam:\n\";
        foreach my $key (keys %desired) {
            print \" - $key $desired{$key}\\n\";
        }
        print \" - Port $desired{Port}\\n\" if exists $desired{Port};
        return;
    }

    open my $out, '>', $config_file or die \"Erro ao escrever $config_file: $!\";
    print $out @lines;
    close $out;

    print \"✅ sshd_config endurecido com sucesso.\n\";

    if (!$dry_run && !$auto) {
        print \"Deseja reiniciar o sshd agora? [s/N] \";
        chomp(my $resp = <STDIN>);
        if (lc($resp) eq 's') {
            system(\"sudo systemctl restart sshd\") == 0
                ? print \"🔁 sshd reiniciado com sucesso.\n\"
                : print \"❌ Falha ao reiniciar sshd.\n\";
        }
    } elsif ($auto) {
        system(\"sudo systemctl restart sshd\");
    }
}

# PHP-2372: Desativa exposição de versão do PHP via expose_php = Off
sub php_2372 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'    } @ARGV;

    print "[PHP-2372] Verificando configuração expose_php...\n";

    # Descobre o arquivo php.ini em uso
    my $ini_path = `php --ini 2>/dev/null | grep \"Loaded Configuration File\"`;
    $ini_path =~ s/.*?:\\s+//;
    chomp $ini_path;

    unless (-f $ini_path) {
        print "❌ Não foi possível localizar o arquivo php.ini.\n";
        return;
    }

    print "📄 Usando $ini_path\n";

    open my $in, '<', $ini_path or die "Erro ao ler $ini_path: $!";
    my @lines = <$in>;
    close $in;

    my $found = 0;
    my $modified = 0;

    for (@lines) {
        if (/^\\s*expose_php\\s*=/) {
            $found = 1;
            if (/=\\s*On/i) {
                $_ = "expose_php = Off\n";
                $modified = 1;
            }
        }
    }

    if (!$found) {
        push @lines, "\n; Adicionado por hardening PHP-2372\nexpose_php = Off\n";
        $modified = 1;
    }

    if ($dry_run) {
        print "🔍 Modo simulação: expose_php seria definido como Off.\n";
        return;
    }

    if ($modified) {
        open my $out, '>', $ini_path or die "Erro ao escrever em $ini_path: $!";
        print $out @lines;
        close $out;
        print "✅ expose_php definido como Off.\n";
    } else {
        print "✔️  expose_php já está definido como Off.\n";
    }

    print "🔁 Deseja reiniciar o servidor web (ex: apache/nginx/php-fpm)? [s/N] ";
    chomp(my $resp = <STDIN>);
    if (lc($resp) eq 's' || $auto) {
        print "Informe o nome do serviço (ex: php-fpm, apache2, nginx): ";
        chomp(my $svc = <STDIN>);
        system("sudo systemctl restart $svc") == 0
            ? print "✅ Serviço $svc reiniciado.\n"
            : print "❌ Falha ao reiniciar $svc.\n";
    }
}

# PHP-2376: Desativa allow_url_fopen para evitar downloads remotos via PHP
sub php_2376 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'    } @ARGV;

    print "[PHP-2376] Verificando configuração allow_url_fopen...\n";

    # Descobre o php.ini ativo
    my $ini_path = `php --ini 2>/dev/null | grep \"Loaded Configuration File\"`;
    $ini_path =~ s/.*?:\\s+//;
    chomp $ini_path;

    unless (-f $ini_path) {
        print "❌ Não foi possível localizar o arquivo php.ini.\n";
        return;
    }

    print "📄 Usando $ini_path\n";

    open my $in, '<', $ini_path or die "Erro ao ler $ini_path: $!";
    my @lines = <$in>;
    close $in;

    my $found = 0;
    my $modified = 0;

    for (@lines) {
        if (/^\\s*allow_url_fopen\\s*=/) {
            $found = 1;
            if (/=\\s*On/i) {
                $_ = "allow_url_fopen = Off\n";
                $modified = 1;
            }
        }
    }

    if (!$found) {
        push @lines, "\n; Adicionado por hardening PHP-2376\nallow_url_fopen = Off\n";
        $modified = 1;
    }

    if ($dry_run) {
        print "🔍 Modo simulação: allow_url_fopen seria definido como Off.\n";
        return;
    }

    if ($modified) {
        open my $out, '>', $ini_path or die "Erro ao escrever em $ini_path: $!";
        print $out @lines;
        close $out;
        print "✅ allow_url_fopen definido como Off.\n";
    } else {
        print "✔️  allow_url_fopen já está definido como Off.\n";
    }

    print "🔁 Deseja reiniciar o servidor web (ex: apache/nginx/php-fpm)? [s/N] ";
    chomp(my $resp = <STDIN>);
    if (lc($resp) eq 's' || $auto) {
        print "Informe o nome do serviço (ex: php-fpm, apache2, nginx): ";
        chomp(my $svc = <STDIN>);
        system("sudo systemctl restart $svc") == 0
            ? print "✅ Serviço $svc reiniciado.\n"
            : print "❌ Falha ao reiniciar $svc.\n";
    }
}

# LOGG-2146: Verifica e rotaciona arquivos de log (incluindo subdiretórios)
sub logg_2146 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'    } @ARGV;

    print "[LOGG-2146] Verificando presença do logrotate...\n";
    my $has_logrotate = system("command -v logrotate > /dev/null 2>&1") == 0;

    unless ($has_logrotate) {
        print "❌ logrotate não está instalado. Por favor instale com: sudo pacman -S logrotate\n";
        return;
    }

    print "🔎 Verificando arquivos .log órfãos de rotação em /var/log/**...\n";
    my @logfiles = grep { -f $_ } glob("/var/log/**/*.log");

    my @rotated;
    foreach my $conf (</etc/logrotate.d/*>, "/etc/logrotate.conf") {
        open my $fh, '<', $conf;
        while (<$fh>) {
            push @rotated, $1 if m{^(/var/log/[^ ]+)};
        }
        close $fh;
    }

    my %rotated_map = map { $_ => 1 } @rotated;
    my @unmanaged = grep { !$rotated_map{$_} } @logfiles;

    if (!@unmanaged) {
        print "✅ Todos os arquivos .log em /var/log estão sendo rotacionados.\n";
        return;
    }

    print "⚠️  Arquivos sem rotação configurada:\n";
    foreach my $log (@unmanaged) {
        print "   - $log\n";
    }

    if ($dry_run) {
        print "🔍 Modo simulação: seriam criadas regras de rotação para esses arquivos.\n";
        return;
    }

    if (!$auto) {
        print "Deseja configurar rotação padrão para esses arquivos? [s/N] ";
        chomp(my $resp = <STDIN>);
        return unless lc($resp) eq 's';
    }

    my $conf_path = '/etc/logrotate.d/custom-unmanaged-logs';
    open my $out, '>', $conf_path or die "Erro ao criar $conf_path: $!";

    print $out "# Criado automaticamente por hardening LOGG-2146\n";
    foreach my $log (@unmanaged) {
        print $out <<"EOF";
$log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
EOF
    }
    close $out;

    print "✅ Regras de rotação criadas em $conf_path.\n";
}

# BANN-7126: Adiciona um banner legal em /etc/issue e /etc/issue.net
sub bann_7126 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'     } @ARGV;

    my @targets = ('/etc/issue', '/etc/issue.net');

    my @banner = (
        "╔══════════════════════════════════════════════════════╗",
        "║        ⚠️  ACESSO RESTRITO AO SISTEMA ⚠️           ║",
        "╚══════════════════════════════════════════════════════╝",
        "",
        "Este sistema é de uso exclusivo de usuários autorizados.",
        "",
        "Todas as atividades são monitoradas e registradas.",
        "Usuários não autorizados estarão sujeitos a sanções administrativas,",
        "civis e criminais, conforme a legislação vigente.",
        "",
        "Ao continuar, você declara estar ciente e concorda com esses termos.",
        ""
    );

    foreach my $file (@targets) {
        print "[BANN-7126] Verificando banner em $file...\n";

        my $needs_update = 1;
        if (-f $file) {
            open my $in, '<', $file or die "Erro ao ler $file: $!";
            my @lines = <$in>;
            close $in;
            if (grep { /ACESSO RESTRITO|Todas as atividades/ } @lines) {
                print "✔️  Banner já presente em $file.\n";
                $needs_update = 0;
            }
        }

        next unless $needs_update;

        if ($dry_run) {
            print "🔍 Modo simulação: o seguinte conteúdo seria escrito em $file:\n\n";
            print "$_\n" for @banner;
            next;
        }

        if (!$auto) {
            print "Deseja aplicar o banner legal em $file? [s/N] ";
            chomp(my $resp = <STDIN>);
            next unless lc($resp) eq 's';
        }

        open my $out, '>', $file or die "Erro ao escrever $file: $!";
        print $out "$_\n" for @banner;
        close $out;

        print "✅ Banner aplicado com sucesso em $file.\n";
    }
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

