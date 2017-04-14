#!/usr/bin/perl
########################################################################
# Developed by Hugo Maza M.
# hugo.maza@gmail.com
# 
# miquiloni is a Web UI for LXC Servers management
# 
# Writen in free style Perl-CGI + Apache + MySQL + Javascript + CSS
# 
# <one line to give the program's name and a brief idea of what it does.>
# Copyright (C) <year>  <name of author>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
########################################################################
use CGI::Carp qw(fatalsToBrowser);
use strict;
use FindBin qw($RealBin);
use CGI;
# use Page::Paginator;
use Tie::File;
use Log::Man;

our(%input, %VAR, %MSG, %PRM, $username, $html, $header, $footer, $module, $module_file, $theme, $dbh, $encKey);
my $VERSION = 0.1;
require 'common.pl';
%VAR = get_vars();
$encKey = getEncKey();
$username = get_session();
$theme = get_theme();
%PRM = get_permissions();
%MSG = loadLang('index');

my $consulta = new CGI;
my @pares = $consulta->param;
foreach my $par ( @pares ){
	$input{"$par"} = $consulta->param("$par");
}
$module = $input{'mod'};

require "$VAR{themes_path}/$theme/theme.pl";
$header = header();
$footer = footer();
$header = common_header() . $header;

if ( $username  eq 'Guest' and $module ne 'login' ) {
	$html .= login();
} else {
	
	unless ( $module ) {
		$module = $VAR{'init_mod'};
	}
	
	$module_file = $module . '.pl';
	
	$html .= $header unless $input{'shtl'};
	if ( -e "$VAR{'modules_dir'}/$module_file" ) {
		# $html .= vermod();
		if ( $PRM{$module} ) {
			$html .= vermod();
		} else {
			$html .= qq"<br /><b>Error 401.</b> Access denied: $module => \$PRM{$module} : $PRM{$module}" . "<br />" x 30;
		}
	} else {
		$html .= qq"<br /><b>Error 404.</b> That module doesn't exist: $module" . "<br />" x 30;
	}
	$html .= $footer unless $input{'shtl'};
}

print "Content-Type: text/html\n\n";
print $html;

exit;

sub get_header_footer {
	require "$VAR{themes_path}/$theme/theme.pl";
	my $header = header();
	my $footer = footer();
	
	return ($header, $footer);
}

sub common_header {
	my $header = qq~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>MIQUILONI :: LXC Management Tool</title>
	<meta name="keywords" content="virtualization, lxc, containers, snapshot, recovery, linux" />
	<meta name="description" content="LXC Linux Containers administrator" />
	<link href="themes/$theme/css/style.css" rel="stylesheet">~;
	
	return  $header;
}
