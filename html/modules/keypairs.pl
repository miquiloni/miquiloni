%MSG = loadLang('Key_Pairs');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Key_Pairs_Management}</div>~ unless $input{'shtl'};


if ( $input{submod} eq 'deletePrivateKey' ) {
	unlink "$VAR{keyPath}/$input{keyName}";
	unlink "$VAR{keyPath}/$input{keyName}.pub";
	
	connected();
	my $sth1 = $dbh->prepare("DELETE FROM keyPairOwner WHERE keyPairName = '$input{keyName}'");
	$sth1->execute();
	$sth1->finish;
	$dbh->disconnect if $dbh;
	
	my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("DELETE:KeyPair:keyPairName=$input{keyName}");
	
	print "Location: index.cgi?mod=keypairs\n\n";
	# UPDATE keyPairOwner set idUser = '2' where keyPairName = 'hugomaza.key'
}



if ( $input{submod} eq 'downloadPrivateKey' ) {
	open(FILE, "<$VAR{keyPath}/$input{keyName}");
	my @file = <FILE>;
	close FILE;
	
	# print "Content-Type:application/x-download\n";
	print "Content-type: application/octet-stream\n";
	print "Content-Disposition: attachment; filename=$input{keyName}\n\n";
	print @file;
	
	my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("DOWNLOAD:KeyPair:keyPairName=$input{keyName}");
	
	exit;
	
	# open(FILE, "<$VAR{keyPath}/$input{keyName}");
	# binmode FILE;
	# local $/ = \10240;
	# while (<FILE>){
	    # print $_;
	# }
	# close FILE;
}


if ( $input{submod} eq 'createNewKeyPair' ) {
	if ( $input{newKeyPairName} =~ /^[a-z0-9_-]{4,20}$/ ) {
		my $newkeyName = $input{newKeyPairName} . '.key';
		
		unless ( -e "$VAR{keyPath}/$newkeyName" ) {
			chdir $VAR{keyPath};
			my $command = `ssh-keygen -t rsa -f $newkeyName`;
			chmod 0600, $newkeyName;
			
			connected();
			my $sth = $dbh->prepare("SELECT idUser FROM users WHERE username = '$username'");
			$sth->execute();
			my ($idUser) = $sth->fetchrow_array;
			$sth->finish;
			
			my $insert_string = "INSERT INTO keyPairOwner (keyPairName, idUser) VALUES ('$newkeyName', '$idUser')";
			$sth = $dbh->prepare("$insert_string");
			$sth->execute();
			$sth->finish;
			$dbh->disconnect if $dbh;
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("NEW:KeyPair:keyPairName=$newkeyName");
			
			print "Location: index.cgi?mod=keypairs\n\n";
		} else {
			$html .= qq~<font color="#BB0000">$MSG{Key_Pair} <b>$input{newKeyPairName}</b> $MSG{already_exists}.</font> $MSG{Please_go} <a href="javascript:history.back();">$MSG{back}</a> $MSG{and_try_with_other_name}.~;
		}
	} else {
		$html .= qq~<font color="#BB0000">$MSG{Input_not_valid_Must_contains_4_characters_at_least_and_must_has}</font>~;
	}
}


unless ( $input{submod} ) {
	connected();
	my $sth = $dbh->prepare("SELECT k.keyPairName FROM keyPairOwner k, users u WHERE k.idUser = u.idUser AND u.username = '$username'");
	$sth->execute();
	my $keyName = $sth->fetchall_arrayref;
	$sth->finish;
	
	my %KN;
	for my $i ( 0 .. $#{$keyName} ) {
		$KN{$keyName->[$i][0]} = 1;
	}
	
	
	$html .= qq~
	<div class="mastergrid" style="width: 600px; height: 400px">
	<table class="mastergrid" cellpadding="0" cellspacing="0">
	<tr>
		<td class="gridHeader" style="max-width:400px">$MSG{Public_Key}</td>
		<td class="gridHeader" style="max-width:100px">$MSG{Unix_Creation_Date}</td>
		<td class="gridHeader" style="max-width:100px">$MSG{Download_Private_Key}</td>
		<td class="gridHeader" style="max-width:40px">$MSG{Delete}</td>
	</tr>
	~;
	
	my @lsKeys = split(/\n/, `ls $VAR{keyPath}`);
	for my $file ( @lsKeys ) {
		unless ( $file =~ /pub$/ ) {
			my $creationDate = localtime((stat( "$VAR{keyPath}/$file" ))[9]);
			my $justKeyName = $file;
			$justKeyName =~ s/.key$//;
			
			$html .= qq~
			<tr class="gridRowData">
				<td class="gridData" style="max-width:400px">$justKeyName</td>
				<td class="gridData" style="max-width:100px">$creationDate</td>
				<td class="gridData" style="max-width:100px; text-align: center">
				~;
				
				if ( $KN{$file} ) {
					$html .= qq~<a href="index.cgi?mod=keypairs&submod=downloadPrivateKey&keyName=$file"><img src="../images/download-32x22.png" style="height: 20px;" /></a>~;
				} else {
					$html .= qq~<img src="../images/download-32x22-unable.png" style="height: 20px;" />~;
				}
				
				$html .= qq~</td><td class="gridData" style="max-width:40px; text-align: center">~;
				
				if ( $KN{$file} ) {
					$html .= qq~<a href="index.cgi?mod=keypairs&submod=deletePrivateKey&keyName=$file" onclick="return confirm('$MSG{Are_you_sure_you_want_to_continue_deleting_the_Key_Pair}: $justKeyName?')"><img src="../images/trashcan-32x36.png" style="height: 20px;" /></a>~;
				} else {
					$html .= qq~<img src="../images/trashcan-32x36-unable.png" style="height: 20px;" />~;
				}
				
			$html .= qq~
			</td>
			</tr>
			~;
		}
	}
	
	$html .= qq~
	</table>
	</div>
	
	<br />
	<br />
	<br />
	
	
	
	<form name="theform" method="get" action="index.cgi" onSubmit="return myFunctionEval();">
	<input type="hidden" name="mod" value="keypairs">
	<input type="hidden" name="submod" value="createNewKeyPair">
	<input type="hidden" name="shtl" value="1">
	$MSG{Name_for_a_new_SSH_Key_Pair}:<br />
	<input type="text" name="newKeyPairName" style="width: 150px;" maxlength="20" id="name2eval"> &nbsp; 
	<button class="blueLightButton">$MSG{Generate}</button>
	</form>
	
	
	<p id="badResult"></p>
	
	<script>
		function myFunctionEval() {
			var x;
			
			x = document.getElementById("name2eval").value;
			
			if (!/^[a-z0-9_-]{4,20}\$/.test(x)) {
				document.getElementById("badResult").innerHTML = '<font color="#BB0000">$MSG{Input_not_valid_Must_contains_4_characters_at_least_and_must_has}</font>';
				return false;
			} else {
				document.getElementById("badResult").innerHTML = '<font color="#1E90FF">$MSG{Generating_the_new_Key_Pair}</font>';
			}
		}
	</script>
	~;
}

return $html;
1;
