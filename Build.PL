use strict;
use vars qw(%PREREQ %RECOMMEND);

eval { require Module::Build; };

if($@) {
   warn "Module::Build failed: $@\n";
   warn "Falling back to MakeMaker ...\n";
   do 'Makefile.PL' or die "Error including Makefile.PL: $!";
} else {
   do 'PREREQ' or die "Error including PREREQ: $@";
   Module::Build->new(
      module_name => 'Sys::Info',
      license     => 'perl',
      requires    => \%PREREQ,
      recommends  => \%RECOMMEND,
      sign        => 0,
      dist_author => 'Burak Gursoy <burak@cpan.org>',
   )->create_build_script;
}
