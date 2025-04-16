#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use Cwd qw(realpath);
use File::Glob qw(bsd_glob);
use File::Spec;
use utf8;
binmode STDOUT, ":utf8";

# 1. Verificar se git está disponível
my $git_found = 0;
foreach my $dir (split /:/, $ENV{PATH}) {
    if (-x "$dir/git") {
        $git_found = 1;
        last;
    }
}
die "\x{26A0} git não encontrado no PATH.\n" unless $git_found;

# 2. Ler .env do diretório do script
my $env_file = "$Bin/.env";
my $git_dirs = '';
my $git_bare_repos = '';
if (-f $env_file) {
    open my $fh, '<', $env_file or die "\x{26A0} Erro ao abrir .env: $!";
    while (<$fh>) {
        chomp;
        s/#.*//;  # remove comentários
        s/^\s+|\s+$//g;
        $git_dirs = $1 if /^GIT_REPOS\s*=\s*["']?(.+?)["']?$/;
        $git_bare_repos = $1 if /^GIT_BARE_REPOS\s*=\s*["']?(.+?)["']?$/;
    }
    close $fh;
}

# 3. Expandir GIT_REPOS
my @repos;
foreach my $pattern (split /\s+/, $git_dirs) {
    $pattern = "$Bin/$pattern" if $pattern !~ m{^[/~]};
    push @repos, grep { -d $_ } bsd_glob($pattern);
}

# 4. Expandir GIT_BARE_REPOS
my @bare_repos;
foreach my $entry (split /\s+/, $git_bare_repos) {
    if ($entry =~ /^([^:]+):(.+)$/) {
        my ($bare, $worktree) = ($1, $2);
        $bare = "$Bin/$bare" if $bare !~ m{^[/~]};
        $worktree = "$Bin/$worktree" if $worktree !~ m{^[/~]};
        foreach my $bare_exp (bsd_glob($bare)) {
            foreach my $wt_exp (bsd_glob($worktree)) {
                push @bare_repos, [$bare_exp, $wt_exp] if -d $bare_exp && -d $wt_exp;
            }
        }
    }
}

# 5. Função para verificar repositórios normais
sub check_repo {
    my ($dir) = @_;
    print "\x{21E8} Verificando repositório: $dir\n";
    return print "    \x{2757} Não é repositório Git.\n" unless -d "$dir/.git";

    my $branch = `git -C "$dir" branch --show-current 2>/dev/null`;
    chomp $branch;
    return print "    \x{2757} HEAD destacado ou branch indefinido.\n" unless $branch;

    system("git", "-C", $dir, "fetch", "--quiet") == 0
        or return print "    \x{26A0} git fetch falhou.\n";

    my @log = `git -C "$dir" log --oneline --no-merges HEAD..origin/$branch 2>/dev/null`;
    if ($? != 0) {
        return print "    \x{26A0} git log falhou ou branch remoto inexistente.\n";
    }

    if (@log) {
        print "    \x{21E8} $branch está atrás de origin/$branch: ", scalar(@log), " commits\n";
        print map { "       - $_" } @log;
    } else {
        print "    \x{21E8} $branch está atualizado com origin/$branch.\n";
    }
}

# 6. Função para verificar repositórios bare com work-tree
sub check_bare_repo {
    my ($git_dir, $worktree) = @_;
    print "\x{21E8} Verificando repositório bare: $git_dir (work-tree: $worktree)\n";
    return print "    \x{2757} $git_dir não é bare.\n"
        unless `git --git-dir="$git_dir" rev-parse --is-bare-repository 2>/dev/null` =~ /true/;

    my $branch = `git --git-dir="$git_dir" --work-tree="$worktree" branch --show-current 2>/dev/null`;
    chomp $branch;
    return print "    \x{2757} HEAD destacado ou branch indefinido.\n" unless $branch;

    system("git", "--git-dir=$git_dir", "--work-tree=$worktree", "fetch", "--quiet") == 0
        or return print "    \x{26A0} git fetch falhou.\n";

    my @log = `git --git-dir="$git_dir" --work-tree="$worktree" log --oneline --no-merges -- HEAD..origin/$branch 2>/dev/null`;
    if ($? != 0) {
        return print "    \x{26A0} git log falhou ou branch remoto inexistente.\n";
    }

    if (@log) {
        print "    \x{21E8} $branch está atrás de origin/$branch: ", scalar(@log), " commits\n";
        print map { "       - $_" } @log;
    } else {
        print "    \x{21E8} $branch está atualizado com origin/$branch.\n";
    }
}

# 7. Executar verificações
check_repo($_) for @repos;
check_bare_repo(@$_) for @bare_repos;

