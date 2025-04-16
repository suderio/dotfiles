#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use Cwd qw(realpath);
use File::Glob qw(bsd_glob);
use File::Spec;
use utf8;
binmode STDOUT, ":utf8";

my $mode = shift @ARGV // '';

# Detecta se terminal suporta cores ANSI
my $USE_COLOR = 1;
if ($ENV{NO_COLOR} || ! -t STDOUT) {
    $USE_COLOR = 0;
}

# Cores ANSI (usadas apenas se $USE_COLOR for verdadeiro)
my $RED    = $USE_COLOR ? "\e[31m" : '';
my $YELLOW = $USE_COLOR ? "\e[33m" : '';
my $GREEN  = $USE_COLOR ? "\e[32m" : '';
my $CYAN   = $USE_COLOR ? "\e[36m" : '';
my $RESET  = $USE_COLOR ? "\e[0m"  : '';

# Verificar se git está disponível
my $git_found = 0;
foreach my $dir (split /:/, $ENV{PATH}) {
    if (-x "$dir/git") {
        $git_found = 1;
        last;
    }
}
die "${RED}\x{26A0} Erro:${RESET} git não encontrado no PATH.\n" unless $git_found;

# Ler .env
my $env_file = "$Bin/.env";
my ($git_dirs, $git_bare_repos, $git_sync_repos) = ('', '', '');
if (-f $env_file) {
    open my $fh, '<', $env_file or die "${RED}\x{26A0} Erro:${RESET} ao abrir .env: $!\n";
    while (<$fh>) {
        chomp;
        s/#.*//;
        s/^\s+|\s+\$//g;
        $git_dirs = $1 if /^GIT_REPOS\s*=\s*"?(.+?)"?$/;
        $git_bare_repos = $1 if /^GIT_BARE_REPOS\s*=\s*"?(.+?)"?$/;
        $git_sync_repos = $1 if /^GIT_SYNC_REPOS\s*=\s*"?(.+?)"?$/;
    }
    close $fh;
}

# Montar lista de repositórios permitidos para sync
my %sync_allowed;
foreach my $pattern (split /\s+/, $git_sync_repos) {
    $pattern = "$Bin/$pattern" if $pattern !~ m{^[/~]};
    foreach my $match (bsd_glob($pattern)) {
        my $resolved = realpath($match);
        $sync_allowed{$resolved} = 1 if defined $resolved;
    }
}

# Expandir GIT_REPOS
my @repos;
foreach my $pattern (split /\s+/, $git_dirs) {
    $pattern = "$Bin/$pattern" if $pattern !~ m{^[/~]};
    push @repos, grep { -d $_ } bsd_glob($pattern);
}

# Expandir GIT_BARE_REPOS
my @bare_repos;
foreach my $entry (split /\s+/, $git_bare_repos) {
    if ($entry =~ /^([^:]+):(.+)$/) {
        my ($bare, $worktree) = ($1, $2);
        $bare = "$Bin/$bare" if $bare !~ m{^[/~]};
        $worktree = "$Bin/$worktree" if $worktree !~ m{^[/~]};
        foreach my $bare_exp (bsd_glob($bare)) {
            foreach my $wt_exp (bsd_glob($worktree)) {
                 push @bare_repos, [$bare_exp, $wt_exp] if -d $bare_exp && -d $wt_exp;

#                if (-d $bare_exp && -d $wt_exp) {
#                    my $actual_worktree = `git --git-dir=$bare_exp config --get core.worktree 2>/dev/null`;
#                    chomp $actual_worktree;
#                    my $resolved_worktree = realpath($wt_exp);
#                    my $resolved_actual = realpath($actual_worktree);
#                    if (defined $resolved_worktree && defined $resolved_actual && $resolved_worktree eq $resolved_actual) {
#                        push @bare_repos, [$bare_exp, $wt_exp];
#                    } else {
#                        print "${YELLOW}\x{2757} Aviso:${RESET} Ignorando $bare_exp: core.worktree não corresponde a $wt_exp\n";
#                    }
#                }
            }
        }
    }
}

sub handle_repo {
    my ($dir, $is_bare, $worktree) = @_;
    my @git_base = $is_bare ? ("--git-dir=$dir", "--work-tree=$worktree") : ("-C", $dir);
    my $label = $is_bare ? "$dir (bare)" : $dir;
    my $sync_path = realpath($is_bare ? $dir : $dir);

    print "\n\x{21E8} ${CYAN}Verificando:${RESET} $label\n";

    my $branch = `git @git_base branch --show-current 2>/dev/null`;
    chomp $branch;
    return print "   \x{2757} ${YELLOW}Aviso:${RESET} HEAD destacado ou branch indefinido.\n" unless $branch;

    system("git", @git_base, "fetch", "--quiet") == 0
        or return print "   \x{26A0} ${RED}Erro:${RESET} git fetch falhou.\n";

    #my $can_ff = system("git", @git_base, "merge-base", "--is-ancestor", "HEAD", "origin/$branch") == 0;

    my $merge_base_output = `git @git_base merge-base --is-ancestor HEAD origin/$branch 2>/dev/null`;
    my $merge_base_status = $?;
    my $can_ff = $merge_base_status == 0;
    my @ahead = `git @git_base rev-list origin/$branch..HEAD 2>/dev/null`;
    my @behind = `git @git_base rev-list HEAD..origin/$branch 2>/dev/null`;

    if ($mode eq 'sync') {
        unless ($sync_allowed{$sync_path}) {
            print "   \x{2757} ${YELLOW}Aviso:${RESET} Repositório não autorizado para sync.\n";
            return;
        }

        if (@behind && $can_ff) {
            print "   \x{21E8} ${GREEN}Atualizando via fast-forward...${RESET}\n";
            system("git", @git_base, "merge", "--ff-only", "origin/$branch");
        } elsif (@behind) {
            print "   \x{2757} ${YELLOW}Aviso:${RESET} Existem commits remotos, mas não é possível fast-forward.\n";
        } else {
            print "   \x{21E8} Nenhum commit remoto pendente.\n";
        }

        if (@ahead) {
            print "   \x{21E8} Enviando commits locais para origin/$branch...\n";
            system("git", @git_base, "push", "origin", $branch);
        } else {
            print "   \x{21E8} Nenhum commit local para enviar.\n";
        }
    } else {
        if (@behind) {
            print "   \x{2757} ${YELLOW}Aviso:${RESET} $branch está atrás de origin/$branch: ", scalar(@behind), " commit(s)\n";
            my @log = `git @git_base log --oneline --no-merges HEAD..origin/$branch`;
            print map { "      - $_" } @log;
        } else {
            print "   \x{21E8} $branch está atualizado.\n";
        }
        if (@ahead) {
            print "   \x{2757} ${YELLOW}Aviso:${RESET} Existem commits locais não enviados: ", scalar(@ahead), " commit(s)\n";
        }
    }
}

handle_repo($_, 0, undef) for @repos;
foreach my $bare (@bare_repos) {
    my ($git_dir, $worktree) = @$bare;
    # Expandir corretamente ~ para worktree, se necessário
    # $git_dir = glob($git_dir) if $git_dir =~ /^~/;
    # $worktree = glob($worktree) if $worktree =~ /^~/;
    handle_repo($git_dir, 1, $worktree);
}
