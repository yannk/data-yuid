# $Id$

use Config;
BEGIN {
    die "A 64-bit Perl is required"
        unless $Config{use64bitint};
}

use inc::Module::Install;

name('Data-YUID');
abstract('Distributed unique ID allocator');
author('Six Apart <cpan@sixapart.com>');
version_from('lib/Data/YUID.pm');
license('perl');
no_index(directory => 't');
sign(0);

include('ExtUtils::AutoInstall');

requires('Danga::Socket');
requires('URI::Escape');

install_script('bin/yuidd');

auto_include();
auto_install();

&WriteAll;
