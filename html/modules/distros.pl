%MSG = loadLang('distros');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Linux_Distributions}</div>~ unless $input{'shtl'};

if ( ($input{query} eq 'createData') and $input{Customer_Number} and $input{Password2Query} ) {
	connected();
	my $sth = $dbh->prepare("INSERT INTO dataRemoteQuery (Customer_Number, Password2Query) VALUES ('$input{Customer_Number}', '$input{Password2Query}')");
	$sth->execute();
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("INSERT:dataRemoteQuery:Customer_Number=$input{Customer_Number}:Password2Query=$input{Password2Query}:");
	
	print "Location: index.cgi?mod=distros\n\n";
}

if ( ($input{query} eq 'updateData') and $input{Customer_Number} and $input{Password2Query} ) {
	connected();
	my $sth = $dbh->prepare("UPDATE dataRemoteQuery SET Customer_Number = '$input{Customer_Number}', Password2Query = '$input{Password2Query}' WHERE idData = '1')");
	$sth->execute();
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	$log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("UPDATE:dataRemoteQuery:Customer_Number=$input{Customer_Number}:Password2Query=$input{Password2Query}:");
	
	print "Location: index.cgi?mod=distros\n\n";
}

if ( $input{query} eq 'buildDistroList' ) {
	connected();
	my $sth = $dbh->prepare("SELECT Customer_Number, Password2Query FROM dataRemoteQuery WHERE idData = '1'");
	$sth->execute();
	my @remote = $sth->fetchrow_array;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	my $list = `curl -d "Customer_Number=$remote[0]&Password2Query=$remote[1]" https://miquiloni.org/remote_query_distros.cgi`;
	
	if ( $list ) {
		my @distros = split(/\n/, $list);
		
		connected();
		my $sth1 = $dbh->prepare("TRUNCATE distros");
		$sth1->execute();
		$sth1->finish;
		
		for my $line ( @distros ) {
			my ($desc, $distro, $release, $arch) = split(/\,/, $line);
			
			my $sth = $dbh->prepare("INSERT INTO distros (distroData, showData) VALUES ('$distro-$release-$arch', '$desc')");
			$sth->execute();
			$sth->finish;
			
			$log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("BUILD:ADDdistroList:distroData=$distro-$release-$arch:showData=:$desc");
		}
	}
	
	$dbh->disconnect if ($dbh);
	
	print "Location: index.cgi?mod=distros\n\n";
}




connected();
my $sth = $dbh->prepare("SELECT Customer_Number, Password2Query FROM dataRemoteQuery WHERE idData = '1'");
$sth->execute();
my @remote = $sth->fetchrow_array;
$sth->finish;
$dbh->disconnect if ($dbh);

if ( $remote[0] and $remote[1] ) {
	my $list = `curl -d "Customer_Number=$remote[0]&Password2Query=$remote[1]" https://miquiloni.org/remote_query_distros.cgi`;
	
	if ( $list ) {
		connected();
		my $sth = $dbh->prepare("SELECT * FROM distros");
		$sth->execute();
		my $distroIhave = $sth->fetchall_arrayref;
		$sth->finish;
		$dbh->disconnect if ($dbh);
		
		my %myDistro;
		for my $i ( 0 .. $#{$distroIhave} ) {
			$myDistro{$distroIhave->[$i][1]} = $distroIhave->[$i][2];
		}
		
		my %currentDistro;
		my @distros = split(/\n/, $list);
		for my $line ( @distros ) {
			my ($desc, $distro, $release, $arch) = split(/\,/, $line);
			$currentDistro{"$distro-$release-$arch"} = $desc;
		}
		
		$html .= qq~
		<div style="padding: 40px 0 0 40px;">
		$MSG{Legends}:<br>
		<table cellpadding="0" cellspacing="2">
		<tr><td style="color: #FFA500"><b>++</b></td><td>$MSG{Distro_is_missing_in_your_Distro_List}</td></tr>
		<tr><td style="color: #A52A2A"><b>--</b></td><td>$MSG{Distro_No_longer_supported}</td></tr>
		<tr><td style="color: #008000">Ok</td><td>$MSG{Everything_is_Ok}</td></tr>
		</table>
		<br><br>
		$MSG{Distro_List}:
		<br>
		<table cellpadding="0" cellspacing="2">
		~;
		
		foreach my $key ( sort keys %currentDistro ) {
			if ( $myDistro{$key} ) {
				$html .= qq~<tr><td style="color: #008000; padding-right: 6px">Ok</td><td style="color: #008000">$myDistro{$key}</td></tr>~;
				putWarning(qq~~);
			} else {
				$html .= qq~<tr><td style="color: #FFA500; padding-right: 6px"><b>++</b></td><td style="color: #FFA500"> $currentDistro{$key}</td></tr>~;
				putWarning(qq~$MSG{Your_current_Distro_List_have_some_issues}.<br>$MSG{Go_to} <a href="index.cgi?mod=distros">$MSG{Distros}</a> $MSG{section_and_correct_the_problem}~);
			}
		}
		
		foreach my $key ( sort keys %myDistro ) {
			unless ( $currentDistro{$key} ) {
				$html .= qq~<tr><td style="color: #A52A2A; padding-right: 6px"><b>--</b></td><td style="color: #A52A2A">$myDistro{$key}</td></tr>~;
				putWarning(qq~$MSG{Your_current_Distro_List_have_some_issues}.<br>$MSG{Go_to} <a href="index.cgi?mod=distros">$MSG{Distros}</a> $MSG{section_and_correct_the_problem}~);
			}
		}
		$html .= qq~
		</table>
		<br><br>
		
		<form method="post" action="index.cgi">
		<input type="hidden" name="mod" value="distros">
		<input type="hidden" name="query" value="buildDistroList">
		<button class="blueLightButton">$MSG{Build_Distro_List}</button>
		</form>
		</div>
		~;
		
		
	} else {
		$html .= qq~
		<div style="padding: 40px 0 0 40px;">
		<font color="#BB0000">$MSG{You_have_not_correctly_configured_your_Query_data}.</font><br>
		$MSG{This_is_for_connect_to_a_remote_Server_and}<br>
		<br>
		$MSG{Please_copy_and_paste_correctly_your_data}.<br>
		<br>
		
		<form method="post" action="index.cgi">
		<input type="hidden" name="mod" value="distros">
		<input type="hidden" name="query" value="updateData">
		<table cellpadding="0" cellcpacing="0">
		<tr><td align="right">Customer Number: </td><td><input type="text" name="Customer_Number" value="$remote[0]"></td></tr>
		<tr><td align="right">Password to Query: </td><td><input type="text" name="Password2Query" value="$remote[1]"></td></tr>
		<tr><td align="right"> &nbsp; </td><td><button class="blueLightButton" type="submit" class="btn">$MSG{Save}</button></td></tr>
		</table>
		
		</form>
		</div>
		~;
		
		putWarning(qq~$MSG{You_have_not_correctly_configured_your_Query_data}.<br>$MSG{Go_to} <a href="index.cgi?mod=distros">$MSG{Distros}</a> $MSG{section_and_follow_instructions}~);
	}
	
	
	
	
} else {
	$html .= qq~
	<div style="padding: 40px 0 0 40px;">
	<font color="#BB0000">$MSG{You_have_not_configured_your_Query_data}.</font><br>
	$MSG{This_is_for_connect_to_a_remote_Server_and}<br>
	<br>
	$MSG{Please_go_to_the} <a href="https://miquiloni.org/index.cgi?mod=register" target="_blank">$MSG{register_link}</a> $MSG{and_requesT_for_your_data_connection}.<br>
	<br>
	$MSG{Then_read_your_Email_and_fill_the_next_form_and}.<br>
	<br>
	
	<form method="post" action="index.cgi">
	<input type="hidden" name="mod" value="distros">
	<input type="hidden" name="query" value="createData">
	<table cellpadding="0" cellcpacing="0">
	<tr><td align="right">Customer Number: </td><td><input type="text" name="Customer_Number"></td></tr>
	<tr><td align="right">Password to Query: </td><td><input type="text" name="Password2Query"></td></tr>
	<tr><td align="right"> &nbsp; </td><td><button class="blueLightButton" type="submit" class="btn">$MSG{Save}</button></td></tr>
	</table>
	
	</form>
	</div>
	~;
	
	putWarning(qq~$MSG{You_have_not_configured_your_Query_data}.<br>$MSG{Go_to} <a href="index.cgi?mod=distros">$MSG{Distros}</a> $MSG{section_and_follow_instructions}~);
}

sub putWarning {
	open (FILE, ">$VAR{db_dir}/distros.updated");
	print FILE shift;
	close FILE;
}

return $html;
1;
