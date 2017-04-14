%MSG = loadLang('Sectors');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Sector_Management}</div>~ unless $input{'shtl'};

unless ( $input{submod} ) {
	connected();
	my $sth = $dbh->prepare("SELECT * FROM sector");
	$sth->execute();
	my $sectors = $sth->fetchall_arrayref;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	
	$html .= qq~
	<div id="grid" style="width: 90%; height: 300px;"></div>
	
	<script>
	\$(function () {
	    \$('\#grid').w2grid({
	        name: 'grid',
	        header: '$MSG{List_of_Sectors}',
	        show: {
				header    : true,
	            footer    : true,
	            toolbar   : true
	        },
	        columns: [
	            { field: 'sectorName', caption: '$MSG{Sector_Name}', size: '15%', sortable: true, searchable: true },
	            { field: 'description', caption: '$MSG{Description}', size: '58%', sortable: true },
	            { field: 'UTCtimeZone', caption: 'UTCtimeZone', size: '12%', sortable: true },
	            { field: 'UTCDSTtimeZone', caption: 'UTCDSTtimeZone', size: '15%', sortable: true },
	        ],
	        records: [
	        ~;
	        
			for my $i ( 0 .. $#{$sectors} ) {
				$html .= qq~{
				recid: '$sectors->[$i][0]',
				sectorName: '$sectors->[$i][1]',
				description: '$sectors->[$i][2]',
				UTCtimeZone: '$sectors->[$i][3]',
				UTCDSTtimeZone: '$sectors->[$i][4]',
				},~;
			}
	        
	        $html .= qq~
	        ],
	        onClick: function(event) {
	            var grid = this;
	            //var form = w2ui.form;
	            console.log(event);
	            event.onComplete = function () {
	                var sel = grid.getSelection();
	                console.log(sel);
	                if (sel.length == 1) {
	                    recid  = sel[0];
	                    var html_link = 'index.cgi?mod=sectors&submod=edit_record&idSector='+recid;
	                    window.open(html_link, '_top');
	                }
	            }
	        }
	    });
	});
	</script>
	~;
}

if ( $input{submod} eq 'edit_record' ) {
	connected();
	my $sth = $dbh->prepare("SELECT * FROM sector WHERE idSector = '$input{idSector}'");
	$sth->execute();
	my @data = $sth->fetchrow_array;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	$html .= qq~
		<form method="get" action="index.cgi" target="_top">
		<input type="hidden" name="mod" value="sectors">
		<input type="hidden" name="submod" value="save_record">
		<input type="hidden" name="idSector" value="$data[0]">
		
		<table cellpadding="0" cellspacing="0" class="formTitle">
		<tr><td style="font-size: 12px">$MSG{Editing_record}: <b>$data[1]</b></td></tr>
		</table>
		
		<table cellpadding="0" cellspacing="0" class="form">
		
		<tr><td align="right" width="30%">$MSG{Sector_Name}: </td><td width="70%"><input type="text" name="sectorName" value="$data[1]" maxlength="16"></td></tr>
		<tr><td align="right" width="30%">$MSG{Description}: </td><td width="70%"><input type="text" name="description" value="$data[2]" style="width: 500px;"></td></tr>
		<tr><td align="right" width="30%">UTCtimeZone: </td><td width="70%"><input type="text" name="UTCtimeZone" value="$data[3]"></td></tr>
		<tr><td align="right" width="30%">UTCDSTtimeZone: </td><td width="70%"><input type="text" name="UTCDSTtimeZone" value="$data[4]"></td></tr>
		
		</table>
		
		<table cellpadding="0" cellspacing="0" class="formFooter">
		<tr><td><button value="Save" class="blueLightButton">$MSG{Save}</button>
		</form>
		&nbsp; &nbsp; &nbsp; <a class="redButton" href="index.cgi?mod=sectors&submod=delete_record&idSector=$data[0]" onclick="return confirm('$MSG{Are_you_sure_you_want_to_continue_deleting_the_Sector}: $data[1]?')">$MSG{Delete}</a>
		&nbsp; &nbsp; &nbsp; <a class="greyButton" href="index.cgi?mod=sectors&submod=new_sector&idSector=$data[0]">$MSG{NEW_Sector}</a>
		&nbsp; &nbsp; &nbsp; <a class="greyButton" href="index.cgi?mod=sectors">$MSG{Back_to_list}</a>
		</td></tr>
		</table>
		
		
		
		<br><br>
	~;
	
}

if ( $input{submod} eq 'new_sector' ) {
	$html .= qq~
		<form method="get" action="index.cgi" target="_top">
		<input type="hidden" name="mod" value="sectors">
		<input type="hidden" name="submod" value="new_record">
		
		<table cellpadding="0" cellspacing="0" class="formTitle">
		<tr><td style="font-size: 12px">$MSG{Creating_new_record}</b></td></tr>
		</table>
		
		<table cellpadding="0" cellspacing="0" class="form">
		
		<tr><td align="right" width="30%">$MSG{Sector_Name}: </td><td width="70%"><input type="text" name="sectorName" value="$data[1]" maxlength="16"></td></tr>
		<tr><td align="right" width="30%">$MSG{Description}: </td><td width="70%"><input type="text" name="description" value="$data[2]" style="width: 500px;"></td></tr>
		<tr><td align="right" width="30%">UTCtimeZone: </td><td width="70%"><input type="text" name="UTCtimeZone" value="$data[3]"></td></tr>
		<tr><td align="right" width="30%">UTCDSTtimeZone: </td><td width="70%"><input type="text" name="UTCDSTtimeZone" value="$data[4]"></td></tr>
		
		</table>
		
		<table cellpadding="0" cellspacing="0" class="formFooter">
		<tr><td><button class="blueLightButton" value="Save" class="btn">$MSG{Save}</button>
		&nbsp; &nbsp; &nbsp; <a class="greyButton" href="index.cgi?mod=sectors">$MSG{Back_to_list}</a>
		</td></tr>
		</table>
		
		</form>
		
		<br><br>
	~;
	
}

if ( $input{submod} eq 'save_record' ) {
	if ( $input{idSector} ) {
		connected();
		my $sth = $dbh->prepare("UPDATE sector SET 
		sectorName='$input{sectorName}',
		description='$input{description}',
		UTCtimeZone='$input{UTCtimeZone}',
		UTCDSTtimeZone='$input{UTCDSTtimeZone}'
		WHERE idSector='$input{idSector}'");
		$sth->execute();
		$sth->finish;
		$dbh->disconnect if $dbh;
		
		my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
		$log->Log("UPDATE:Sector:idSector=$input{idSector};sectorName=$input{sectorName};description=$input{description};UTCtimeZone=$input{UTCtimeZone};UTCDSTtimeZone=$input{UTCDSTtimeZone}");
		
		print "Location: index.cgi?mod=sectors\n\n";
		
	}
}

if ( $input{submod} eq 'new_record' ) {
	if ( $input{sectorName} ) {
		$dbh->do("LOCK TABLES sector WRITE");
		my $insert_string = "INSERT INTO sector (sectorName, description, UTCtimeZone, UTCDSTtimeZone) VALUES (
		'$input{sectorName}', '$input{description}', '$input{UTCtimeZone}', '$input{UTCDSTtimeZone}')";
		$sth = $dbh->prepare("$insert_string");
		$sth->execute();
		$sth->finish;
		$dbh->do("UNLOCK TABLES");
		$dbh->disconnect if $dbh;
		
		my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
		$log->Log("NEW:Sector:sectorName=$input{sectorName};description=$input{description};UTCtimeZone=$input{UTCtimeZone};UTCDSTtimeZone=$input{UTCDSTtimeZone}");
		
		print "Location: index.cgi?mod=sectors\n\n";
	} else {
		$html .= qq~<font color="#BB0000">Sector Name is mandatory</font><br /><br /><br /><br />~;
	}
}

if ( $input{submod} eq 'delete_record' ) {
	connected();
	$dbh->do("LOCK TABLES sector WRITE");
	my $sth = $dbh->prepare(qq~DELETE FROM sector WHERE idSector = '$input{idSector}'~);
	$sth->execute();
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	$dbh->disconnect if $dbh;
	
	my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("DELETE:Sector:idSector=$input{idSector}");
	
	print "Location: index.cgi?mod=sectors\n\n";
}



return $html;
1;
