#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);

# 1. Verificar se o comando `git` está disponível no PATH
my $git_encontrado = 0;
if ($ENV{PATH}) {
    for my $dir (split /:/, $ENV{PATH}) {
        if (-x "$dir/git") {  # verifica se existe um executável 'git' no dir
            $git_encontrado = 1;
            last;
        }
    }
}
if (!$git_encontrado) {
    die "Erro: o comando 'git' não foi encontrado. Instale o Git ou ajuste o PATH.\n";
}

# 2. Ler o arquivo .env no diretório do script para obter GIT_DIR
my $env_file = "$Bin/.env";
my $git_dir_value = undef;
if (-e $env_file) {
    open my $envfh, '<', $env_file 
        or die "Erro: não foi possível ler o arquivo .env: $!\n";
    while (<$envfh>) {
        chomp;
        s/\r$//;                             # remove carriage return (se houver, para Windows)
        next if /^\s*#/;                     # ignora linhas de comentário
        next if /^\s*$/;                     # ignora linhas em branco
        if (/^\s*GIT_DIR\s*=\s*(.+)$/) {
            # Captura o valor após "GIT_DIR=" incluindo quaisquer caracteres
            my $val = $1;
            $val =~ s/\s+#.*$//;             # remove comentários embutidos após o valor (se existirem)
            $val =~ s/^["'](.*)["']$/$1/;    # remove aspas envolventes, se presentes
            $val =~ s/\s+$//;               # remove espaços em branco à direita
            $val =~ s/^\s+//;               # remove espaços em branco à esquerda
            $git_dir_value = $val;
            last;
        }
    }
    close $envfh;
}

# Se não definiu GIT_DIR (nenhum valor encontrado)
if (!defined($git_dir_value) || $git_dir_value eq '') {
    die "Erro: Nenhum diretório configurado em GIT_DIR (arquivo .env).\n";
}

# 3. Expandir os diretórios listados em GIT_DIR
my @dir_patterns = split /\s+/, $git_dir_value;
my @directories_to_check;
foreach my $pattern (@dir_patterns) {
    # Se o caminho for relativo (não começa com '~' ou '/'), torna-o relativo ao diretório do script
    if ($pattern !~ m{^[/~]}) {
        $pattern = "$Bin/$pattern";
    }
    # Usa glob para expandir ~ e curingas (*)
    my @matches = glob($pattern);
    if (!@matches) {
        warn "Aviso: O padrão '$pattern' não corresponde a nenhum diretório.\n";
    }
    foreach my $dirpath (@matches) {
        # Apenas adiciona se for diretório existente
        if (-d $dirpath) {
            push @directories_to_check, $dirpath;
        } else {
            warn "Aviso: '$dirpath' não é um diretório válido, será ignorado.\n";
        }
    }
}

# Remove duplicatas da lista (caso algum padrão gere o mesmo caminho duas vezes)
# e ordena os diretórios para uma saída consistente (opcional)
my %seen;
@directories_to_check = grep { !$seen{$_}++ } @directories_to_check;
@directories_to_check = sort @directories_to_check;

# 4. Iterar sobre cada diretório e verificar o status do repositório Git
foreach my $repo_dir (@directories_to_check) {
    print ">>> Verificando repositório: $repo_dir\n";
    # Verifica se contém .git
    unless (-e "$repo_dir/.git") {
        print "    [Ignorado] '$repo_dir' não é um repositório Git válido (diretório .git não encontrado).\n";
        next;
    }
    # Obtém o nome do branch atual
    chomp(my $branch = `git -C "$repo_dir" branch --show-current 2>&1`);
    if ($? != 0) {
        # Se o comando falhou, emite erro e passa para o próximo
        print "    [Erro] Falha ao obter o branch atual em $repo_dir.\n";
        next;
    }
    if (!$branch) {
        # Branch vazio indica HEAD destacada (detached HEAD)
        print "    [Aviso] O repositório está com HEAD destacado (sem branch ativo) - não é possível verificar commits remotos.\n";
        next;
    }
    # Fetch no repositório (atualiza informações de origin)
    my $fetch_status = system("git", "-C", "$repo_dir", "fetch", "--quiet");
    if ($fetch_status != 0) {
        print "    [Erro] Falha ao executar 'git fetch' em $repo_dir (branch $branch).\n";
        next;
    }
    # Verifica commits novos no origin/branch
    # Captura saída do git log (commits em origin/branch que não estão no HEAD local)
    open my $logfh, "-|", "git", "-C", "$repo_dir", 
                     "log", "--oneline", "--no-merges", "HEAD..origin/$branch"
        or do {
            print "    [Erro] Não foi possível executar git log em $repo_dir.\n";
            next;
        };
    my @log_lines = <$logfh>;
    close $logfh;
    my $log_exit = $?;  # status de saída do git log
    # Remove quebras de linha dos commits
    chomp @log_lines;
    if ($log_exit != 0) {
        # Caso git log tenha retornado erro (por ex, branch remoto não existe)
        print "    [Erro] Não foi possível obter diferenças para 'origin/$branch'. Verifique se o branch remoto existe.\n";
        next;
    }
    if (@log_lines && @log_lines > 0) {
        my $count = scalar @log_lines;
        print "    -> Branch '$branch' tem $count novo(s) commit(s) no remoto 'origin':\n";
        foreach my $line (@log_lines) {
            print "       - $line\n";
        }
    } else {
        print "    -> Branch '$branch' está atualizado em relação a 'origin'. Nenhum novo commit encontrado.\n";
    }
}

