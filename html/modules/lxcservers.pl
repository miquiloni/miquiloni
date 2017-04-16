%MSG = loadLang('LXCServers');

my $html;
$html .= qq~<div class="contentTitle">$MSG{LXC_Server_Management}</div>~ unless $input{'shtl'};



if ( $input{submod} eq 'save_record' ) {
	if ( $input{idServer} ) {
		connected();
		my $sth = $dbh->prepare("UPDATE lxcservers SET 
		hostName='$input{hostName}',
		IPv4='$input{IPv4}',
		memory='$input{memory}',
		cpuMake='$input{cpuMake}',
		cpuModel='$input{cpuModel}',
		cpuSpeed='$input{cpuSpeed}',
		privateKey='$input{privateKey}',
		createContainersMode='$input{createContainersMode}',
		storageProvisioningMode='$input{storageProvisioningMode}',
		shortDescription='$input{shortDescription}',
		idSector='$input{sectorId}' 
		WHERE idServer='$input{idServer}'");
		$sth->execute();
		$sth->finish;
		$dbh->disconnect if $dbh;
		
		my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
		$log->Log("UPDATE:LXC Server:idServer=$input{idServer}:hostName=$input{hostName};IPv4=$input{IPv4};IPv6=$input{IPv6};memory=$input{memory};cpuMake=$input{cpuMake};cpuModel=$input{cpuModel};cpuSpeed=$input{cpuSpeed};privateKey=$input{privateKey};Password_for_LXC_Server=$input{Password_for_LXC_Server};createContainersMode=$input{createContainersMode};storageProvisioningMode=$input{storageProvisioningMode};shortDescription=$input{shortDescription};idSector=$input{sectorId}'");
		
		if ( $input{passwd4LXCserver} ) {
			my $passwd = $input{passwd4LXCserver};
			my $updateKey = `/usr/bin/sshpass -p "$passwd" /usr/bin/ssh -o StrictHostKeyChecking=no root\@$input{IPv4} 'ls -d /root/.ssh'`;
			chomp $updateKey;
			
			if ( $updateKey ne '/root/.ssh' ) {
				system(qq~/usr/bin/sshpass -p "$passwd" /usr/bin/ssh -o StrictHostKeyChecking=no root\@$input{IPv4} 'mkdir /root/.ssh'~);
				system(qq~/usr/bin/sshpass -p "$passwd" /usr/bin/ssh -o StrictHostKeyChecking=no root\@$input{IPv4} 'touch /root/.ssh/authorized_keys'~);
			}
			
			my $privateKey = "$VAR{keyPath}/$input{privateKey}.pub";
			system(qq~/usr/bin/sshpass -p "$passwd" /usr/bin/scp -o StrictHostKeyChecking=no $privateKey root\@$input{IPv4}:/root/.ssh/authorized_keys~);
			
			if ( $updateKey ne '/root/.ssh' ) {
				system(qq~/usr/bin/sshpass -p "$passwd" /usr/bin/ssh -o StrictHostKeyChecking=no root\@$input{IPv4} 'chmod 640 /root/.ssh'~);
				system(qq~/usr/bin/sshpass -p "$passwd" /usr/bin/ssh -o StrictHostKeyChecking=no root\@$input{IPv4} 'chmod 640 /root/.ssh/authorized_keys'~);
			}
		}
		
		print "Location: index.cgi?mod=lxcservers&idServer=$input{idServer}\n\n";
		
	} else {
		$html .= qq~<font color="#BB0000">$MSG{Passwords_does_not_match}</font>~;
	}
}

if ( $input{submod} eq 'delete_record' ) {
	connected();
	$sth = $dbh->prepare("SELECT COUNT(idContainer) FROM containers WHERE idServer = '$input{idServer}'");
	$sth->execute();
	my ($countContainers) = $sth->fetchrow_array;
	$sth->finish;
	
	unless ( $countContainers ) {
		$dbh->do("LOCK TABLES lxcservers WRITE");
		my $sth = $dbh->prepare(qq~DELETE FROM lxcservers WHERE idServer = '$input{idServer}'~);
		$sth->execute();
		$sth->finish;
		$dbh->do("UNLOCK TABLES");
		$dbh->disconnect if $dbh;
		
		my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
		$log->Log("DELETE:LXC Server:idServer=$input{idServer}:");
		
		print "Location: index.cgi?mod=lxcservers\n\n";
	} else {
		$dbh->disconnect if $dbh;
		$html .= qq~<font color="#CC0000">$MSG{There_are_some_Containers_Delete_them_first}</font><br />~;
	}
	
		
}

if ( $input{submod} eq 'new_record' ) {
	
	if ( $input{hostName} ) {
		if ( $input{IPv4} ) {
			
			connected();
			$sth = $dbh->prepare("SELECT idServer FROM lxcservers WHERE hostName = '$input{hostName}'");
			$sth->execute();
			my ($idServerTest) = $sth->fetchrow_array;
			$sth->finish;
			
			unless ($idServerTest) {
				my $insert_string = "INSERT INTO lxcservers (
				hostName, IPv4, IPv6, memory, cpus, cpuMake, cpuModel, cpuSpeed, privateKey, createContainersMode, storageProvisioningMode, shortDescription, idSector
				) VALUES (
				'$input{hostName}',
				'$input{IPv4}',
				'$input{IPv6}',
				'$input{memory}',
				'$input{cpus}',
				'$input{cpuMake}',
				'$input{cpuModel}',
				'$input{cpuSpeed}',
				'$input{privateKey}',
				'$input{createContainersMode}',
				'$input{storageProvisioningMode}',
				'$input{shortDescription}',
				'$input{sectorId}')";
				$sth = $dbh->prepare("$insert_string");
				$sth->execute();
				$sth->finish;
				
				# $html .= $insert_string . "<br><br>";
				
				$sth = $dbh->prepare("SELECT idServer, cpus FROM lxcservers WHERE hostName = '$input{hostName}'");
				$sth->execute();
				my ($idNewServer, $cpus) = $sth->fetchrow_array;
				$sth->finish;
				
				$insert_string = '';
				foreach my $cpuId ( 0 .. $cpus-1 ) {
					foreach my $quarter ( 1 .. 4 ) {
						$insert_string = "INSERT INTO cpus (idServer, cpuId, cpuCuarter) VALUES ('$idNewServer', '$cpuId', '$quarter')";
						$sth = $dbh->prepare("$insert_string");
						$sth->execute();
						$sth->finish;
					}
				}
				
				$dbh->disconnect if $dbh;
				
				my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
				$log->Log("NEW:LXC Server:idServer=$idNewServer;Hostname=$input{hostName}:");
				
				# print "Location: index.cgi?mod=lxcservers\n\n";
				
			} else {
				$html .= qq~<font color="#BB0000">LXC Server alredy exists</font><br />~;
			}
		} else {
			$html .= qq~<font color="#BB0000">$MSG{LXC_Server_alredy_exists}</font><br />~;
		}
	} else {
		$html .= qq~<font color="#BB0000">$MSG{IPV4_is_mandatory}</font><br />~;
	}
}



connected();
$sth = $dbh->prepare("SELECT srv.*, s.sectorName FROM lxcservers srv, sector s WHERE srv.idSector = s.idSector ORDER BY hostName");
$sth->execute();
my $lxcservers = $sth->fetchall_arrayref;
$sth->finish;
$dbh->disconnect if ($dbh);

$html .= qq~
<div id="grid" style="width: 100%; height: 400px;"></div>

<script>
\$(function () {
    \$('\#grid').w2grid({
        name: 'grid',
        header: 'List of Names',
        show: { 
            footer    : true,
            toolbar    : true
        },
        columns: [
            { field: 'hostName', caption: 'Host Name', size: '100px', sortable: true, searchable: true },
            { field: 'IPv4', caption: 'IPv4', size: '140px', sortable: true },
            { field: 'memory', caption: '$MSG{Memory}', size: '80px', sortable: true },
            { field: 'cpus', caption: 'CPUs', size: '50px', sortable: true },
            { field: 'cpuMake', caption: '$MSG{CPU_Make}', size: '100px', sortable: true, searchable: true },
            { field: 'cpuModel', caption: '$MSG{CPU_Model}', size: '100px', sortable: true, searchable: true },
            { field: 'cpuSpeed', caption: '$MSG{CPU_Speed}', size: '100px', sortable: true },
            { field: 'privateKey', caption: '$MSG{Private_Key}', size: '150px', sortable: true },
            { field: 'storageProvisioningMode', caption: '$MSG{Storage}', size: '100px', sortable: true, searchable: true },
            { field: 'sectorName', caption: '$MSG{Sector_Name}', size: '150px', sortable: true, searchable: true },
            { field: 'ShortDescription', caption: '$MSG{Description}', size: '200px', sortable: true, searchable: true }
        ],
        records: [
        ~;
        
		use LXC::LXCWrapper;
		for my $i ( 0 .. $#{$lxcservers} ) {
			my $keyPair = $VAR{keyPath} . '/' . $lxcservers->[$i][9];
			my $lxc = LXC::LXCWrapper->new($lxcservers->[$i][2], $keyPair);
			
			my $status = '#00BB00';
			$status = '#BB0000' if $lxc->{error};
			my $err = ' - '.$lxc->{error} if $lxc->{error};
			my $lxcServer = qq~<font color="$status"><b>$lxcservers->[$i][1]</b>$err</font>~;
			
			$html .= qq~{
			recid: '$lxcservers->[$i][0]',
			hostName: '$lxcServer',
			IPv4: '$lxcservers->[$i][2]',
			memory: '$lxcservers->[$i][4]',
			cpus: '$lxcservers->[$i][5]',
			cpuMake: '$lxcservers->[$i][6]',
			cpuModel: '$lxcservers->[$i][7]',
			cpuSpeed: '$lxcservers->[$i][8]',
			privateKey: '$lxcservers->[$i][9]',
			createContainersMode: '$lxcservers->[$i][10]',
			storageProvisioningMode: '$lxcservers->[$i][11]',
			sectorName: '$lxcservers->[$i][15]',
			ShortDescription: '$lxcservers->[$i][12]'
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
                    var html_link = 'launcher.cgi?mod=lxcservers_edit&idServer='+recid;
                    window.open(html_link, 'edition_frame');
                } else {
					var html_link = 'launcher.cgi?mod=lxcservers_edit';
                    window.open(html_link, 'edition_frame');
                    form.clear();
                }
            }
        }
    });
});
</script>

<br />
~;

$html .= qq~

<iframe name="edition_frame" src="launcher.cgi?mod=lxcservers_edit&idServer=$input{idServer}" class="edition_frame" onload="this.style.height=this.contentDocument.body.scrollHeight +'px';"></iframe>

~;


return $html;
1;
