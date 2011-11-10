package Dist::Zilla::Plugin::ModuleBuild::OptionalXS;
# ABSTRACT: Build a module that has an XS component that only optionally needs to be built.
# AUTHORITY
# VERSION

use Moose;

extends 'Dist::Zilla::Plugin::ModuleBuild';

my $pp_check = <<'EOF';
my $build_xs;
$build_xs = 0 if grep { $_ eq '--pp' } @ARGV;
$build_xs = 1 if grep { $_ eq '--xs' } @ARGV;
if (!defined $build_xs) {
  $build_xs = $build->have_c_compiler;
}

unless ($build_xs) {
  $build->build_elements(
    [ grep { $_ ne 'xs' } @{ $build->build_elements } ]
  );
}
EOF

after setup_installer => sub {
  my $self = shift;

  my ($file) = grep { $_->name eq 'Build.PL' } @{ $self->zilla->files };
  my $content = $file->content;

  $content =~ s/(\$build->create_build_script;)/$pp_check$1/;

  $file->content($content);
};

around module_build_args => sub {
  my $orig = shift;
  my $self = shift;

  my $args = $self->$orig(@_);

  $args->{c_source} = 'c';
  $args->{need_compiler} = 0;

  return $args;
};


__PACKAGE__->meta->make_immutable;
