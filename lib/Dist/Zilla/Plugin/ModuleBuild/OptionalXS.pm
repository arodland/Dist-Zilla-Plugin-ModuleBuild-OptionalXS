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

=head1 DESCRIPTION

This module is a L<Dist::Zilla> plugin for building modules that have an XS
component, but that are able to build and function even if there is no C
compiler to build the XS component.

=head1 SYNOPSIS

In your dist.ini:

    [ModuleBuild::OptionalXS]

=head1 BUILD.PL ARGUMENTS

Like L<Dist::Zilla::Plugin::ModuleBuild::XSorPP> this module supports C<--pp>
and C<--xs> options to override the C compiler detection. With C<--pp>, the XS
component won't be built, even if a C compiler is available. With C<--xs>,
Module::Build will try to build the XS component even if it thinks that a C
compiler isn't available (this will almost definitely fail).

=head1 USING WITH HEADERS AND PPPORT

When using this plugin, C<< c_source => 'c' >> will be added to your
L<Module::Build> options. Any include files that you want to use from your
C<.xs> files can be placed in the C<c> directory. If you want to include
C<ppport.h>, add

    [PPPort]
    filename = c/ppport.h

to your dist.ini.
