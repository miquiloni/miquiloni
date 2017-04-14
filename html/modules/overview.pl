%MSG = loadLang('overview');

my $html = qq~<!--This is the empty content for initial module-->~;

$html .= qq~
Welcome to MIQUILONI
~;

open (FILE, "<$VAR{db_dir}/distros.updated");
my ($line) = <FILE>;
close FILE;

if ( $line ) {
	$html .= qq~
	<div style="padding: 40px 0 0 40px; color: #BB0000">
	<b>$MSG{Warning}!</b><br />
	$line
	</div>
	~;
}


return $html;
1;
