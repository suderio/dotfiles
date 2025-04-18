#!/usr/bin/env perl
use strict;
use warnings;

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

