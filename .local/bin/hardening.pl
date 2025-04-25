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
        "║        ⚠️  ACESSO RESTRITO AO SISTEMA ⚠️             ║",
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

# ACCT-9622: Habilita process accounting no sistema
sub acct_9622 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto' } @ARGV;

    print "[ACCT-9622] Verificando presença do pacote acct...\n";
    my $installed = system("pacman -Q acct > /dev/null 2>&1") == 0;

    if (!$installed) {
        print "⚠️  O pacote 'acct' não está instalado.\n";
        if ($dry_run) {
            print "🔍 Modo simulação: 'acct' seria instalado com pacman.\n";
            return;
        }
        if ($auto) {
            print "⚙️  Instalando automaticamente...\n";
            system("sudo pacman -Sy --noconfirm acct") == 0
                or die "❌ Falha ao instalar o pacote acct.\n";
        } else {
            print "Deseja instalar o pacote acct agora? [s/N] ";
            chomp(my $resp = <STDIN>);
            if (lc($resp) eq 's') {
                system("sudo pacman -S acct");
            } else {
                print "❎ Instalação abortada.\n";
                return;
            }
        }
    } else {
        print "✔️  Pacote acct já está instalado.\n";
    }

    if ($dry_run) {
        print "🔍 Modo simulação: o serviço de accounting seria ativado.\n";
        return;
    }

    print "📂 Ativando process accounting com accton...\n";

    # Cria o arquivo de log padrão se não existir
    my $log = '/var/log/pacct';
    unless (-f $log) {
        system("sudo touch $log && sudo chown root:root $log && sudo chmod 600 $log");
    }

    # Habilita accounting
    system("sudo accton $log") == 0
        ? print "✅ Process accounting ativado e registrando em $log\n"
        : print "❌ Falha ao ativar process accounting\n";

    # Verifica se está funcionando
    if (`accton` =~ /is on/) {
        print "📈 Accounting ativo.\n";
    } else {
        print "❗ Accounting ainda não está ativo. Verifique permissões ou logs.\n";
    }
}

# ACCT-9626: Ativa coleta de contabilidade de sistema com sysstat
sub acct_9626 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto' } @ARGV;

    print "[ACCT-9626] Verificando presença do pacote sysstat...\n";
    my $installed = system("pacman -Q sysstat > /dev/null 2>&1") == 0;

    if (!$installed) {
        print "⚠️  O pacote 'sysstat' não está instalado.\n";
        if ($dry_run) {
            print "🔍 Modo simulação: sysstat seria instalado.\n";
            return;
        }
        if ($auto) {
            system("sudo pacman -Sy --noconfirm sysstat") == 0
                or die "❌ Falha ao instalar sysstat.\n";
        } else {
            print "Deseja instalar sysstat agora? [s/N] ";
            chomp(my $resp = <STDIN>);
            if (lc($resp) eq 's') {
                system("sudo pacman -S sysstat");
            } else {
                print "❎ Instalação cancelada.\n";
                return;
            }
        }
    } else {
        print "✔️  sysstat já está instalado.\n";
    }

    my $conf = '/etc/default/sysstat';
    my $found = 0;
    my $modified = 0;

    if (-f $conf) {
        open my $in, '<', $conf or die "Erro ao ler $conf: $!";
        my @lines = <$in>;
        close $in;

        for (@lines) {
            if (/^\\s*ENABLED=\\s*\"?false\"?/i) {
                $_ = "ENABLED=\"true\"\n";
                $found = 1;
                $modified = 1;
            }
        }

        if (!$found) {
            push @lines, "ENABLED=\"true\"\n";
            $modified = 1;
        }

        if ($dry_run) {
            print "🔍 Modo simulação: sysstat seria ativado em $conf.\n";
            return;
        }

        if ($modified) {
            open my $out, '>', $conf or die "Erro ao escrever em $conf: $!";
            print $out @lines;
            close $out;
            print "✅ sysstat ativado no arquivo $conf.\n";
        } else {
            print "✔️  sysstat já estava ativado em $conf.\n";
        }
    } else {
        print "⚠️  Arquivo $conf não encontrado — sysstat pode estar usando configuração padrão.\n";
    }

    if ($dry_run) {
        print "🔍 Modo simulação: sysstat.service seria habilitado e iniciado.\n";
        return;
    }

    system("sudo systemctl enable sysstat.service");
    system("sudo systemctl start sysstat.service");

    print "✅ Serviço sysstat ativado e iniciado.\n";
}

# ACCT-9628: Ativa auditd e configura regras básicas de auditoria
sub acct_9628 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto' } @ARGV;

    print "[ACCT-9628] Verificando presença do pacote audit...\n";
    my $installed = system("pacman -Q audit > /dev/null 2>&1") == 0;

    if (!$installed) {
        print "⚠️  O pacote 'audit' não está instalado.\n";
        if ($dry_run) {
            print "🔍 Modo simulação: pacote audit seria instalado.\n";
            return;
        }
        if ($auto) {
            print "⚙️  Instalando audit automaticamente...\n";
            system("sudo pacman -Sy --noconfirm audit") == 0
                or die "❌ Falha ao instalar audit.\n";
        } else {
            print "Deseja instalar audit agora? [s/N] ";
            chomp(my $resp = <STDIN>);
            if (lc($resp) eq 's') {
                system("sudo pacman -S audit");
            } else {
                print "❎ Instalação cancelada.\n";
                return;
            }
        }
    } else {
        print "✔️  Pacote audit já está instalado.\n";
    }

    if ($dry_run) {
        print "🔍 Modo simulação: auditd seria ativado e regras seriam aplicadas.\n";
        return;
    }

    print "🚀 Ativando e iniciando o serviço auditd...\n";
    system("sudo systemctl enable auditd.service");
    system("sudo systemctl start auditd.service");

    my $status = `systemctl is-active auditd.service`;
    chomp $status;
    if ($status eq "active") {
        print "✅ auditd está ativo.\n";
    } else {
        print "❌ auditd não foi iniciado corretamente. Verifique com journalctl.\n";
        return;
    }

    # Regras básicas
    my $rules_file = "/etc/audit/rules.d/99-hardening.rules";

    print "🛡️  Escrevendo regras básicas em $rules_file...\n";
    open my $out, '>', $rules_file or die "Erro ao escrever $rules_file: $!";

    print $out <<"EOF";
# Regras básicas de auditoria - Segurança mínima recomendada

# Monitoramento de arquivos críticos
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group -p wa -k group_changes
-w /etc/sudoers -p wa -k sudoers_changes

# Uso de comandos sensíveis
-a always,exit -F path=/usr/bin/passwd -F perm=x -k passwd_exec
-a always,exit -F path=/usr/bin/sudo -F perm=x -k sudo_exec
-a always,exit -F path=/usr/bin/chmod -F perm=x -k chmod_exec
-a always,exit -F path=/usr/bin/chown -F perm=x -k chown_exec

# Mudanças de atributos em arquivos
-a always,exit -F arch=b64 -S chown,fchown,fchownat,lchown -k chown_calls
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -k chmod_calls
EOF

    close $out;

    # Aplica imediatamente as regras
    system("sudo augenrules --load") == 0
        ? print "✅ Regras de auditoria carregadas.\n"
        : print "⚠️  Falha ao aplicar regras com augenrules.\n";
}

# TIME-3104: Ativa sincronização de tempo com NTP (systemd-timesyncd)
sub time_3104 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'     } @ARGV;

    print "[TIME-3104] Verificando status da sincronização NTP...\n";

    my $status = `timedatectl status 2>/dev/null`;
    my $active = ($status =~ /NTP service: active/i);
    my $enabled = ($status =~ /System clock synchronized: yes/i);

    if ($active && $enabled) {
        print "✅ Sincronização NTP já está ativa e funcionando.\n";
        return;
    }

    print "⚠️  A sincronização NTP ainda não está ativa.\n";

    if ($dry_run) {
        print "🔍 Modo simulação: systemd-timesyncd seria habilitado e iniciado.\n";
        return;
    }

    if (!$auto) {
        print "Deseja ativar systemd-timesyncd agora? [s/N] ";
        chomp(my $resp = <STDIN>);
        return unless lc($resp) eq 's';
    }

    print "🔧 Habilitando systemd-timesyncd...\n";
    system("sudo systemctl enable systemd-timesyncd.service");
    system("sudo systemctl start systemd-timesyncd.service");

    my $sync = `timedatectl status 2>/dev/null`;
    if ($sync =~ /System clock synchronized: yes/) {
        print "✅ Sincronização NTP ativada com sucesso.\n";
    } else {
        print "❌ Falha ao ativar sincronização NTP. Verifique o serviço systemd-timesyncd.\n";
    }
}

# CRYP-7902: Verifica certificados locais que estão expirados ou prestes a expirar
sub cryp_7902 {
    use POSIX qw(strftime);
    use Time::Piece;
    use File::Find;

    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    print "[CRYP-7902] Verificando certificados locais para expiração...\n";

    my @paths = (
        "/etc/ssl", "/etc/pki", "/usr/local/share/ca-certificates",
        "/etc/letsencrypt/live", "/etc/letsencrypt/archive"
    );

    my @cert_files;
    foreach my $base (@paths) {
        next unless -d $base;
        find(sub {
            return unless -f $_;
            return unless /\.(crt|pem|cer)$/i;
            push @cert_files, $File::Find::name;
        }, $base);
    }

    if (!@cert_files) {
        print "ℹ️  Nenhum certificado encontrado nos diretórios padrão.\n";
        return;
    }

    my $now = localtime;
    my $warning_days = 30;
    my $warn_ts = $now + (60 * 60 * 24 * $warning_days);

    my $expired = 0;
    my $expiring = 0;

    foreach my $cert (@cert_files) {
        my $output = `openssl x509 -enddate -noout -in "$cert" 2>/dev/null`;
        next unless $output =~ /notAfter=(.*)/;

        my $exp_str = $1;
        my $exp_date = Time::Piece->strptime($exp_str, "%b %e %T %Y %Z");

        if ($exp_date < $now) {
            print "❌ [EXPIRADO] $cert → $exp_str\n";
            $expired++;
        } elsif ($exp_date < $warn_ts) {
            print "⚠️  [Vencendo em breve] $cert → $exp_str\n";
            $expiring++;
        }
    }

    if ($expired == 0 && $expiring == 0) {
        print "✅ Todos os certificados estão válidos por pelo menos 30 dias.\n";
    } else {
        print "\nResumo: $expired expirado(s), $expiring vencendo(s) em até 30 dias.\n";
    }
}

# FINT-4350: Instala e inicializa AIDE para verificação de integridade de arquivos
sub fint_4350 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto' } @ARGV;

    print "[FINT-4350] Verificando presença do AIDE...\n";
    my $installed = system("pacman -Q aide > /dev/null 2>&1") == 0;

    if (!$installed) {
        print "⚠️  O pacote 'aide' não está instalado.\n";
        if ($dry_run) {
            print "🔍 Modo simulação: aide seria instalado.\n";
            return;
        }
        if ($auto) {
            system("sudo pacman -Sy --noconfirm aide") == 0
                or die "❌ Falha ao instalar aide.\n";
        } else {
            print "Deseja instalar aide agora? [s/N] ";
            chomp(my $resp = <STDIN>);
            if (lc($resp) eq 's') {
                system("sudo pacman -S aide");
            } else {
                print "❎ Instalação cancelada.\n";
                return;
            }
        }
    } else {
        print "✔️  AIDE já está instalado.\n";
    }

    if ($dry_run) {
        print "🔍 Modo simulação: AIDE seria inicializado e configurado.\n";
        return;
    }

    print "🛠️  Inicializando banco de dados do AIDE...\n";
    system("sudo aide --init") == 0
        ? print "✅ Banco inicial gerado em /var/lib/aide/aide.db.new.gz\n"
        : die "❌ Falha ao gerar banco de dados inicial com aide.\n";

    print "📂 Movendo banco de dados para o local padrão...\n";
    system("sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz") == 0
        ? print "✅ Banco de dados de integridade pronto para uso.\n"
        : print "⚠️  Falha ao mover banco de dados. Verifique permissões.\n";

    print "✅ AIDE está instalado e pronto. Você pode executar futuras verificações com:\n";
    print "   sudo aide --check\n";
}

# TOOL-5002: Verifica presença de ferramentas de automação no sistema
sub tool_5002 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'     } @ARGV;

    print "[TOOL-5002] Verificando ferramentas de automação de gerenciamento...\n";

    my %tools = (
        'ansible'   => 'Ansible',
        'puppet'    => 'Puppet',
        'salt'      => 'SaltStack',
        'chef'      => 'Chef',
        'cf-agent'  => 'CFEngine',
    );

    my @found;
    foreach my $bin (keys %tools) {
        if (system("command -v $bin >/dev/null 2>&1") == 0) {
            push @found, $tools{$bin};
        }
    }

    if (@found) {
        print "✅ Ferramentas de automação detectadas:\n";
        foreach my $t (@found) {
            print "   - $t\n";
        }
    } else {
        print "⚠️  Nenhuma ferramenta de automação encontrada.\n";

        if ($dry_run) {
            print "🔍 Modo simulação: nenhuma ação será tomada.\n";
            return;
        }

        if ($auto) {
            print "⚙️  Instalando Ansible automaticamente...\n";
            system("sudo pacman -Sy --noconfirm ansible") == 0
                ? print "✅ Ansible instalado com sucesso.\n"
                : print "❌ Falha ao instalar Ansible.\n";
        } else {
            print "Deseja instalar o Ansible agora? [s/N] ";
            chomp(my $resp = <STDIN>);
            if (lc($resp) eq 's') {
                system("sudo pacman -S ansible");
            } else {
                print "ℹ️  Você pode instalar com: sudo pacman -S ansible\n";
            }
        }
    }
}

# FILE-7524: Verifica e restringe permissões perigosas de arquivos
sub file_7524 {
    use File::Find;

    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'     } @ARGV;

    print "[FILE-7524] Buscando arquivos com permissões perigosas...\n";

    my @suspects;
    find(sub {
        return unless -f $_;
        my $mode = (stat($_))[2] & 07777;
        return unless $mode == 0777 || $mode == 0666 || $mode == 0755;

        my $path = $File::Find::name;
        my $type = 'arquivo';

        if ($_ =~ /\.(conf|ini)$/i) {
            $type = 'config';
        } elsif ($_ =~ /\.(key|pem)$/i || $_ =~ /id_rsa/) {
            $type = 'chave';
        }

        push @suspects, { path => $path, mode => sprintf("%04o", $mode), type => $type };
    }, '/etc', '/var', '/home', '/opt', '/srv');

    if (!@suspects) {
        print "✅ Nenhum arquivo com permissões perigosas encontrado.\n";
        return;
    }

    print "⚠️  Arquivos com permissões arriscadas:\n";
    foreach my $f (@suspects) {
        print "   [$f->{mode}] $f->{path}\n";
    }

    if ($dry_run) {
        print "🔍 Modo simulação: sugestões de correção listadas abaixo:\n";
        foreach my $f (@suspects) {
            my $new_mode = $f->{type} eq 'chave' ? '600' :
                           $f->{type} eq 'config' ? '640' :
                           $f->{mode} eq '0777' ? '750' :
                           $f->{mode} eq '0666' ? '640' : '755';
            print " → chmod $new_mode $f->{path}\n";
        }
        return;
    }

    if (!$auto) {
        print "Deseja corrigir as permissões automaticamente? [s/N] ";
        chomp(my $resp = <STDIN>);
        return unless lc($resp) eq 's';
    }

    foreach my $f (@suspects) {
        my $new_mode = $f->{type} eq 'chave' ? 0600 :
                       $f->{type} eq 'config' ? 0640 :
                       $f->{mode} eq '0777' ? 0750 :
                       $f->{mode} eq '0666' ? 0640 : 0755;

        if (chmod $new_mode, $f->{path}) {
            printf "✅ Corrigido: %s → %04o\n", $f->{path}, $new_mode;
        } else {
            print "❌ Falha ao corrigir $f->{path}\n";
        }
    }
}

# KRNL-6000: Aplica valores seguros de sysctl para segurança do kernel com backup
sub krnl_6000 {
    use POSIX qw(strftime);

    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'     } @ARGV;

    print "[KRNL-6000] Verificando e aplicando hardening em parâmetros sysctl...\n";

    my %sysctl_recommended = (
        'kernel.kptr_restrict'         => 2,
        'fs.suid_dumpable'             => 0,
        'kernel.randomize_va_space'    => 2,
        'net.ipv4.icmp_echo_ignore_broadcasts' => 1,
        'net.ipv4.conf.all.accept_redirects'   => 0,
        'net.ipv4.conf.all.send_redirects'     => 0,
        'net.ipv4.conf.all.accept_source_route'=> 0,
        'net.ipv4.conf.default.accept_redirects' => 0,
        'net.ipv4.conf.default.send_redirects' => 0,
        'net.ipv4.conf.default.accept_source_route' => 0,
        'net.ipv4.tcp_syncookies'      => 1,
        'net.ipv4.tcp_timestamps'      => 0,
        'net.ipv6.conf.all.accept_redirects' => 0,
        'net.ipv6.conf.default.accept_redirects' => 0,
    );

    my $conf_path = '/etc/sysctl.d/99-hardening.conf';
    my $backup_dir = '/var/backups';
    my $timestamp = strftime("%Y%m%d", localtime);
    my $backup_path = "$backup_dir/sysctl-backup-$timestamp.conf";

    my @to_apply;
    my %current_values;

    foreach my $key (keys %sysctl_recommended) {
        my $current = `sysctl -n $key 2>/dev/null`;
        chomp $current;
        next if $current eq '';  # ignora valores não encontrados

        $current_values{$key} = $current;

        my $expected = $sysctl_recommended{$key};
        if ($current ne "$expected") {
            print "⚠️  $key atual: $current → recomendado: $expected\n";
            push @to_apply, [$key, $expected];
        } else {
            print "✅ $key já está corretamente configurado ($current)\n";
        }
    }

    if (!@to_apply) {
        print "✔️  Todos os parâmetros estão corretos.\n";
        return;
    }

    if ($dry_run) {
        print "🔍 Modo simulação: os seguintes valores seriam aplicados:\n";
        print "   $_->[0] = $_->[1]\n" for @to_apply;
        return;
    }

    if (!$auto) {
        print "Deseja aplicar os valores recomendados e salvar backup? [s/N] ";
        chomp(my $resp = <STDIN>);
        return unless lc($resp) eq 's';
    }

    # Cria diretório de backup se necessário
    system("mkdir -p $backup_dir") unless -d $backup_dir;

    open my $bkp, '>', $backup_path or die "Erro ao criar backup em $backup_path: $!";
    print $bkp "# Backup automático dos parâmetros sysctl antes de hardening ($timestamp)\n";
    for my $key (sort keys %current_values) {
        print $bkp "$key = $current_values{$key}\n";
    }
    close $bkp;

    print "💾 Backup salvo em $backup_path\n";

    # Aplica novos valores e grava config persistente
    open my $out, '>', $conf_path or die "Erro ao escrever em $conf_path: $!";
    print $out "# sysctl hardening - KRNL-6000\n";
    for my $entry (@to_apply) {
        my ($key, $val) = @$entry;
        print $out "$key = $val\n";
        system("sysctl -w $key=$val");
    }
    close $out;

    print "✅ Valores aplicados e persistidos em $conf_path\n";
}

# HRDN-7222: Verifica e restringe o uso de compiladores no sistema
sub hrdn_7222 {
    use File::Find;
    use File::Basename;
    use File::stat;

    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'     } @ARGV;

    print "[HRDN-7222] Verificando presença e permissões de compiladores...\n";

    my @compilers = qw(
        gcc g++ clang cc c++ rustc go javac kotlinc native-image julia
        gfortran ifort nim ghc fpc swiftc zig v nasm as
    );

    my %found;

    # 1. Verificar no PATH
    foreach my $c (@compilers) {
        my $path = `command -v $c 2>/dev/null`;
        chomp $path;
        if ($path && -x $path) {
            $found{$path} = 1;
        }
    }

    # 2. Buscar em /usr/local, /opt, e /home/*
    my @extra_dirs = qw(/usr/local /opt /home);
    find(sub {
        return unless -f $_;
        return unless grep { $_ eq basename($_) } @compilers;
        $found{$File::Find::name} = 1;
    }, @extra_dirs);

    if (!%found) {
        print "✅ Nenhum compilador encontrado no sistema.\n";
        return;
    }

    print "⚠️  Compiladores encontrados:\n";

    my @violations;

    foreach my $path (sort keys %found) {
        my $st = stat($path) or next;
        my $mode = sprintf "%04o", $st->mode & 07777;
        my $owner = getpwuid($st->uid);
        my $perms_ok =
            ($owner eq 'root' && $mode =~ /^7[0-5]0$/) ||   # root-only (750, 740, etc)
            ($path =~ m{^/home/([^/]+)} && $owner eq $1);   # dono do próprio $HOME

        print " - $path [$mode, dono: $owner] ", ($perms_ok ? "✔️ OK\n" : "❌ NÃO SEGURO\n");

        push @violations, { path => $path, mode => $mode, owner => $owner }
            unless $perms_ok;
    }

    if (!@violations) {
        print "✅ Todos os compiladores têm permissões seguras.\n";
        return;
    }

    if ($dry_run) {
        print "\n🔍 Modo simulação: seriam aplicadas as seguintes ações:\n";
        foreach my $v (@violations) {
            my $suggested_owner = ($v->{path} =~ m{^/home/([^/]+)}) ? $1 : 'root';
            print " → chmod 750 $v->{path}; chown $suggested_owner:$suggested_owner $v->{path}\n";
        }
        return;
    }

    if (!$auto) {
        print "\nDeseja corrigir permissões automaticamente? [s/N] ";
        chomp(my $resp = <STDIN>);
        return unless lc($resp) eq 's';
    }

    foreach my $v (@violations) {
        my $path = $v->{path};
        my $suggested_owner = ($path =~ m{^/home/([^/]+)}) ? $1 : 'root';

        system("sudo chmod 750 '$path'");
        system("sudo chown $suggested_owner:$suggested_owner '$path'");

        print "✅ Corrigido: $path → dono: $suggested_owner, modo: 750\n";
    }
}

# HRDN-7222: Remove compiladores órfãos ou fora da whitelist
sub hrdn_7222_prune {
    use File::Find;
    use File::Basename;
    use File::stat;

    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'     } @ARGV;

    my @whitelist = qw(gcc g++ rustc clang go javac julia);  # ex: permitidos
    my %allowed = map { $_ => 1 } @whitelist;

    print "[HRDN-7222] Verificando compiladores não autorizados para possível remoção...\n";

    my @search_dirs = qw(/usr/local /opt /home /usr/bin /usr/sbin /usr/lib /var);

    my @to_remove;

    find(sub {
        return unless -f $_ && -x _;
        my $name = basename($_);
        return unless grep { $_ eq $name } @whitelist or $name =~ /(gcc|g\+\+|cc|clang|c\+\+|go|rustc|javac|julia|zig|v|fpc|ghc|swiftc|nim|as|nasm|kotlinc|native-image)/;

        my $path = $File::Find::name;
        my $base = basename($path);

        my $st = stat($path) or return;
        my $owner = getpwuid($st->uid) || "UNKNOWN";

        my $permitted =
            ($path =~ m{^/home/([^/]+)} && $owner eq $1) ||
            $allowed{$base};

        unless ($permitted) {
            push @to_remove, { path => $path, owner => $owner };
        }
    }, @search_dirs);

    if (!@to_remove) {
        print "✅ Nenhum compilador fora da whitelist encontrado.\n";
        return;
    }

    print "⚠️  Compiladores possivelmente indesejados:\n";
    foreach my $c (@to_remove) {
        print " - $c->{path} [dono: $c->{owner}]\n";
    }

    if ($dry_run) {
        print "\n🔍 Modo simulação: os arquivos acima seriam removidos.\n";
        return;
    }

    if (!$auto) {
        print "\nDeseja remover automaticamente os compiladores listados? [s/N] ";
        chomp(my $resp = <STDIN>);
        return unless lc($resp) eq 's';
    }

    foreach my $c (@to_remove) {
        my $path = $c->{path};
        if (system("sudo rm -f '$path'") == 0) {
            print "🗑️  Removido: $path\n";
        } else {
            print "❌ Falha ao remover: $path\n";
        }
    }
}

# HRDN-7230: Instala scanner de malware (rkhunter) e executa verificação inicial
sub hrdn_7230 {
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    my $auto    = grep { $_ eq '--auto'     } @ARGV;

    print "[HRDN-7230] Verificando presença de scanner de malware...\n";

    my $has_rkhunter    = system("command -v rkhunter >/dev/null 2>&1") == 0;
    my $has_chkrootkit  = system("command -v chkrootkit >/dev/null 2>&1") == 0;

    if ($has_rkhunter || $has_chkrootkit) {
        print "✅ Scanner detectado: " .
            ($has_rkhunter ? "rkhunter " : "") .
            ($has_chkrootkit ? "chkrootkit" : "") . "\n";
    } else {
        print "⚠️  Nenhum scanner encontrado.\n";

        if ($dry_run) {
            print "🔍 Modo simulação: rkhunter seria instalado.\n";
            return;
        }

        if ($auto) {
            print "⚙️  Instalando rkhunter automaticamente...\n";
            system("sudo pacman -Sy --noconfirm rkhunter") == 0
                or die "❌ Falha ao instalar rkhunter.\n";
        } else {
            print "Deseja instalar rkhunter agora? [s/N] ";
            chomp(my $resp = <STDIN>);
            if (lc($resp) eq 's') {
                system("sudo pacman -S rkhunter");
            } else {
                print "ℹ️  Você pode instalar com: sudo pacman -S rkhunter\n";
                return;
            }
        }
    }

    return if $dry_run;

    print "🔄 Atualizando base de dados do rkhunter...\n";
    system("sudo rkhunter --update");

    print "🔍 Executando verificação inicial...\n";
    system("sudo rkhunter --propupd --skip-keypress");
    system("sudo rkhunter --check --skip-keypress");

    if (!$auto) {
        print "Deseja configurar verificação periódica com cron ou systemd? [s/N] ";
        chomp(my $res = <STDIN>);
        return unless lc($res) eq 's';
    }

    my $cron_path = "/etc/cron.daily/rkhunter";
    open my $cron, '>', $cron_path or die "Erro ao criar $cron_path: $!";
    print $cron <<"EOF";
#!/bin/sh
/usr/bin/rkhunter --update > /dev/null
/usr/bin/rkhunter --check --skip-keypress | tee /var/log/rkhunter-cron.log
EOF
    close $cron;
    system("chmod +x $cron_path");
    print "✅ Cron diário criado para verificação com rkhunter.\n";
}

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

sub main {
    my %actions = (
        'boot_5264'         => \&boot_5264,
        'krnl_5820'         => \&krnl_5820,
        'auth_9230'         => \&auth_9230,
        'auth_9262'         => \&auth_9262,
        'auth_9282'         => \&auth_9282,
        'auth_9286'         => \&auth_9286,
        'auth_9328'         => \&auth_9328,
        'file_6354'         => \&file_6354,
        'usb_1000'          => \&usb_1000,
        'usb_1000_restore'  => \&usb_1000_restore,
        'strg_1846'         => \&strg_1846,
        'name_4028'         => \&name_4028,
        'pkgs_7312'         => \&pkgs_7312,
        'pkgs_7320'         => \&pkgs_7320,
        'netw_3200'         => \&netw_3200,
        'unblock_net_protocols' => \&unblock_net_protocols,
        'ssh_7408'          => \&ssh_7408,
        'php_2372'          => \&php_2372,
        'php_2376'          => \&php_2376,
        'logg_2146'         => \&logg_2146,
        'bann_7126'         => \&bann_7126,
        'acct_9622'         => \&acct_9622,
        'acct_9626'         => \&acct_9626,
        'acct_9628'         => \&acct_9628,
        'acct_report'       => \&acct_report,
        'audit_report'      => \&audit_report,
        'time_3104'         => \&time_3104,
        'cryp_7902'         => \&cryp_7902,
        'fint_4350'         => \&fint_4350,
        'fint_schedule'     => \&fint_schedule,
        'tool_5002'         => \&tool_5002,
        'file_7524'         => \&file_7524,
        'krnl_6000'         => \&krnl_6000,
        'krnl_6000_restore' => \&krnl_6000_restore,
        'hrdn_7222'         => \&hrdn_7222,
        'hrdn_7222_prune'   => \&hrdn_7222_prune,
        'hrdn_7230'         => \&hrdn_7230,
    );

    my %descriptions = (
        'boot_5264'         => 'Análise de segurança dos serviços systemd',
        'krnl_5820'         => 'Desativa core dumps via limits.conf',
        'auth_9230'         => 'Configura hashing rounds para senhas',
        'auth_9262'         => 'Instala módulo PAM de força de senha',
        'auth_9282'         => 'Define data de expiração para contas',
        'auth_9286'         => 'Configura idade mínima/máxima de senha',
        'auth_9328'         => 'Define umask padrão mais restrito (027)',
        'file_6354'         => 'Verifica arquivos antigos em /tmp',
        'usb_1000'          => 'Desativa armazenamento USB',
        'usb_1000_restore'  => 'Reativa armazenamento USB',
        'strg_1846'         => 'Desativa suporte a FireWire',
        'name_4028'         => 'Verifica e ajusta domínio DNS do sistema',
        'pkgs_7312'         => 'Atualiza pacotes (rolling updates)',
        'pkgs_7320'         => 'Instala `arch-audit` para vulnerabilidades',
        'netw_3200'         => 'Desativa protocolos desnecessários (dccp, etc)',
        'unblock_net_protocols' => 'Reativa protocolos desativados',
        'ssh_7408'          => 'Aplica hardening na configuração do SSH',
        'php_2372'          => 'Desativa expose_php no php.ini',
        'php_2376'          => 'Desativa allow_url_fopen no php.ini',
        'logg_2146'         => 'Configura rotação de logs em /var/log',
        'bann_7126'         => 'Adiciona banner legal ao /etc/issue e issue.net',
        'acct_9622'         => 'Ativa process accounting (accton)',
        'acct_9626'         => 'Ativa coleta com sysstat (sar, iostat)',
        'acct_9628'         => 'Ativa auditd e regras básicas',
        'acct_report'       => 'Relatório de contabilidade de processos',
        'audit_report'      => 'Relatório dos eventos de auditd',
        'time_3104'         => 'Ativa sincronização com systemd-timesyncd',
        'cryp_7902'         => 'Verifica expiração de certificados SSL',
        'fint_4350'         => 'Instala AIDE e inicializa integridade de arquivos',
        'fint_schedule'     => 'Agendamento de verificação do AIDE',
        'tool_5002'         => 'Verifica presença de ferramentas de automação',
        'file_7524'         => 'Corrige permissões inseguras de arquivos',
        'krnl_6000'         => 'Aplica sysctl seguros e gera backup',
        'krnl_6000_restore' => 'Restaura sysctl a partir de backup salvo',
        'hrdn_7222'         => 'Restringe uso de compiladores por usuários',
        'hrdn_7222_prune'   => 'Remove compiladores não autorizados',
        'hrdn_7230'         => 'Instala e agenda scanner com rkhunter',
    );

    my $action = shift @ARGV // '';
    if ($action eq '--help' or $action eq '-h' or $action eq '') {
        print "\n🔐 Arch Linux Hardening Script (Lynis-based)\n";
        print "Uso: perl $0 <ação> [--dry-run] [--auto]\n\n";
        print "Ações disponíveis:\n";
        foreach my $cmd (sort keys %actions) {
            my $desc = $descriptions{$cmd} // '';
            printf "  %-22s  %s\n", $cmd, $desc;
        }
        print "\nUse --dry-run para simular e --auto para execução sem perguntas.\n";
        exit 0;
    }

    if (exists $actions{$action}) {
        $actions{$action}->();
    } else {
        die "❌ Ação desconhecida: $action\nUse --help para listar as ações disponíveis.\n";
    }
}

main() unless caller;


