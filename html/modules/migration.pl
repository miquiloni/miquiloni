%MSG = loadLang('Migration');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Migration}</div>~ unless $input{'shtl'};

if ( $input{originIdContainer} =~ /\,/ ) {
	$html .= qq~$MSG{We_only_can_migrate_One_Container_at_the_same_time_Please} <a href="javascript:history.back();">$MAG{go_Back}</a> $MSG{and_select_just_One_Container_to_migrate}.~;
	return $html;
	1;
}

if ( $input{originIdContainer} ) {
	connected();
	$sth = $dbh->prepare("SELECT s.IPv4, s.privateKey, c.containerName, c.locked FROM containers c, lxcservers s WHERE c.idServer = s.idServer AND c.idContainer = '$input{originIdContainer}'");
	$sth->execute();
	my ($host, $privateKey, $containerName, $locked) = $sth->fetchrow_array;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	if ( $locked ) {
		$html .= qq~$MSG{Container_is_LOCKED_Please} <a href="javascript:history.back();">$MAG{go_Back}</a> $MSG{and_select_another_Container_to_migrate}.~;
		return $html;
		1;
		
	} else {
		use LXC::LXCWrapper;
		my $lxc = LXC::LXCWrapper->new($host, $VAR{keyPath} . '/' . $privateKey);
		my $response = $lxc->ping($containerName);
		
		if ( $response ne 'STOPPED' ) {
			$html .= qq~$MSG{Container_is_not_STOPPED_Please} <a href="javascript:history.back();">$MAG{go_Back}</a> $MSG{and_STOP_the_Container_to_migrate}.~;
			return $html;
			1;
		}
	}
}

print "Location: index.cgi?mod=containers\n\n" unless $input{originIdContainer};

unless ( $input{submod} ) {
	connected();
	my $sth = $dbh->prepare("SELECT * FROM sector");
	$sth->execute();
	my $sectors = $sth->fetchall_arrayref;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	my $sectorSeleted;
	my $optionSectors = qq~<option value=""> - Please Select - </option>\n~;
	for my $i ( 0 .. $#{$sectors} ) {
		my $selected = $input{idSector} eq $sectors->[$i][0] ? 'selected' : '';
		$sectorSeleted = $sectors->[$i][1] if $selected;
		$optionSectors .= qq~<option value="$sectors->[$i][0]" $selected>$sectors->[$i][1]</option>\n~;
	}
	$html .= qq~
		<form method="get" action="index.cgi">
		<input type="hidden" name="mod" value="migration">
		<input type="hidden" name="originIdContainer" value="$input{originIdContainer}">
		Sector: <select name="idSector" onChange="this.form.submit();">
		$optionSectors
		</select>
		</form>
		<br>
	~;
	
	if ( $input{idSector} ) {
		connected();
		my $sth = $dbh->prepare("SELECT srv.idServer, srv.hostName, srv.memory, srv.cpus, srv.cpuMake, srv.cpuModel, srv.cpuSpeed, s.sectorName FROM lxcservers srv, sector s WHERE srv.idSector = s.idSector AND srv.idSector = '$input{idSector}' ORDER BY hostName");
		$sth->execute();
		my $srvs = $sth->fetchall_arrayref;
		
		my $sth1 = $dbh->prepare("SELECT distribution, release_, architecture, keyPair, idServer, containerName FROM containers WHERE idContainer = '$input{originIdContainer}'");
		$sth1->execute();
		my ($originDistro, $originRelease, $originArch, $originKeyPair, $originIdServer, $originContainerName) = $sth1->fetchrow_array;
		$sth1->finish;
		
		$sth->finish;
		
		my %SRV;
		for my $i ( 0 .. $#{$srvs} ) {
			my @data;
			for my $j ( 1 .. $#{$srvs->[$i]} ) {
				push @data, $srvs->[$i][$j];
			}
			$SRV{$srvs->[$i][0]}{data} = [@data];
		}
		
		my $sth = $dbh->prepare("SELECT idServer, memory, cpu, percentCpu FROM containers");
		$sth->execute();
		my $vps = $sth->fetchall_arrayref;
		$sth->finish;
		$dbh->disconnect if ($dbh);
		
		for my $i ( 0..$#{$vps} ) {
			$SRV{$vps->[$i][0]}{utilizedmemory} += $vps->[$i][1];
			
			my $cpus;
			if ( $vps->[$i][2] =~ /\,/ ) {
				$cpus = scalar(split(/\,/, $vps->[$i][2]));
			} elsif ( $vps->[$i][2] =~ /\-/ ) {
				my ($s, $f) =split(/\-/, $vps->[$i][2]);
				foreach ( $s .. $f ) {
					$cpus ++;
				}
			} else {
				$cpus = 1
			}
			
			if ( $vps->[$i][3] < '100' ) {
				$cpus = 1 / (100 / $vps->[$i][3]) if $cpus eq '1';
			}
			
			$SRV{$vps->[$i][0]}{utilizedcpus} += $cpus;
		}
		
		$html .= qq~
		<div id="grid" style="width: 90%; height: 500px;"></div>
		
		<script>
		\$(function () {
		    \$('\#grid').w2grid({
		        name: 'grid',
		        header: '$MSG{LXC_Servers_available_in_Sector}: $sectorSeleted',
		        show: {
					header    : true,
		            footer    : true,
		            toolbar   : true
		        },
		        columns: [
		            { field: 'hostname', caption: '$MSG{Hostname}', size: '100px', sortable: true, searchable: true },
		            { field: 'freemem', caption: '$MSG{Free_Memory}', size: '200px', sortable: true },
		            { field: 'freecpus', caption: '$MSG{Free_CPUs}', size: '200px', sortable: true },
		            { field: 'cpumake', caption: '$MSG{CPU_Make}', size: '100', sortable: true },
		            { field: 'cpumodel', caption: '$MSG{CPU_Model}', size: '100', sortable: true },
		            { field: 'cpuspeed', caption: '$MSG{CPU_Speed}', size: '100', sortable: true },
		        ],
		        records: [
		        ~;
		        
				foreach my $key ( keys %SRV ) {
					if ( $originIdServer ne $key ) {
						my $freemem = $SRV{$key}{data}[1] - $SRV{$key}{utilizedmemory};
						my $freecpus = $SRV{$key}{data}[2] - $SRV{$key}{utilizedcpus};
						
						my $freememColor = $freemem >= 1 ? '#00BB00' : '#BB0000';
						my $freecpusColor = $freecpusColor >= 1 ? '#00BB00' : '#BB0000';
						
						$html .= qq~{
						recid: '$key-$freemem-$freecpus',
						hostname: '$SRV{$key}{data}[0]',
						freemem: '<font color="$freememColor"><b>$freemem</b></font> of $SRV{$key}{data}[1]',
						freecpus: '<font color="#00BB00"><b>$freecpus</b></font> of $SRV{$key}{data}[2]',
						cpumake: '$SRV{$key}{data}[3]',
						cpumodel: '$SRV{$key}{data}[4]',
						cpuspeed: '$SRV{$key}{data}[5]',
						},~ if $SRV{$key}{data}[0];
					}
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
		                    var html_link = 'index.cgi?mod=migration&submod=select_storage&originIdContainer=$input{originIdContainer}&recid='+recid;
		                    window.open(html_link, '_top');
		                }
		            }
		        }
		    });
		});
		</script>
		~;
	}
}






if ( $input{submod} eq 'select_storage' ) {
	my ($targetIdServer, $memory, $cpus) = split(/\-/, $input{recid});
	
	$html .= qq~
		<script>
		function setVolumeSize(val){
			document.getElementById("volumeSize").value=val;
		}
		</script>
	~;
	
	# $html .= qq~$targetIdServer, $memory, $cpus, $input{originIdContainer}<br><br>~;
	
	connected();
	my $sth = $dbh->prepare("SELECT hostName, IPv4, privateKey FROM lxcservers WHERE idServer = '$targetIdServer'");
	$sth->execute();
	my ($targetHostName, $targetHost, $targetPrivateKey) = $sth->fetchrow_array;
	$sth->finish;
	
	# $sth = $dbh->prepare("SELECT distroData, showData FROM distros WHERE active = '1'");
	# $sth->execute();
	# my $distro = $sth->fetchall_arrayref;
	# $sth->finish;
	
	my $sth1 = $dbh->prepare("SELECT distribution, release_, architecture, keyPair, idServer, containerName FROM containers WHERE idContainer = '$input{originIdContainer}'");
	$sth1->execute();
	my ($originDistro, $originRelease, $originArch, $originKeyPair, $originIdServer, $originContainerName) = $sth1->fetchrow_array;
	$sth1->finish;
	
	$dbh->disconnect if ($dbh);
	
	use LVM::LVMWrapper;
	my $lvm = LVM::LVMWrapper->new($targetHost, "$VAR{keyPath}/$targetPrivateKey");
	my $response = $lvm->vgdisplay();
	
	my $vgSelect;
	
	if ( $response ) {
		foreach my $key ( keys %$response ) {
			my ($lvsize, $lvnom) = split(/\s+/, $response->{$key}[0]);
			if ( $lvnom eq 'MiB' ) {
				$response->{$key}[0] = $lvsize.'M';
			} elsif ( $lvnom eq 'GiB' ) {
				$response->{$key}[0] = $lvsize.'G';
			}
			($lvsize, $lvnom) = split(/\s+/, $response->{$key}[1]);
			if ( $lvnom eq 'MiB' ) {
				$response->{$key}[1] = $lvsize.'M';
			} elsif ( $lvnom eq 'GiB' ) {
				$response->{$key}[1] = $lvsize.'G';
			}
			
			$vgSelect .= qq~$key <input type="radio" name="vg" id="vg" onFocus="setVolumeSize('$response->{$key}[1]')" value="$key" >  ($response->{$key}[1] Free of $response->{$key}[0])<br/>~;
			# $chckd = undef;
		}
	} else {
		$vgSelect .= qq~<font color="#EE0000">$MSG{I_cannot_read_the_list_of_VGs_Please_go_back_and_try_again}.</font><br/>~;
	}
	
	my ($intcpu, $percentcpu) = split(/\./, $cpus);
	# $percentcpu = ".$percentcpu" if $percentcpu;
	$percentcpu = '50' if $percentcpu eq '5';
	
	my $selectPercentCpu;
	if ( $intcpu >= 1 ) {
		$selectPercentCpu .= qq~<select name="percentcpu" style="width: 100px;">~;
		foreach my $prcnt ( 25, 50, 75 ) {
			my $selected = $percentcpu eq $prcnt ? 'selected' : '';
			$selectPercentCpu .= qq~<option value="$prcnt" $selected>$prcnt \%</option>~;
		}
		$selectPercentCpu .= qq~</select>~;
	} else {
		if ( $percentcpu ) {
			my $rest = 100 - $percentcpu;
			foreach my $prcnt ( .25, .50, .75 ) {
				if ( $prcnt <= $rest ) {
					$selectPercentCpu .= qq~<option value="$prcnt">$prcnt \%</option>~;
				} else {
					last;
				}
			}
		}
	}
	
	my $selectCPUs = qq~<select name="cpus" style="width: 100px;">~;
	foreach my $qtyCPUs ( 1 .. $intcpu ) {
		$selectCPUs .= qq~<option value="$qtyCPUs"> $qtyCPUs</option>\n~;
	}
	$selectCPUs .= qq~</select>~;
	
	# my $selectDistro = qq~<select name="distro" style="width: 200px;">~;
	# for my $i ( 0 .. $#{$distro} ) {
		# $selectDistro .= qq~<option value="$distro->[$i][0]">$distro->[$i][1]</option>\n~;
	# }
	# $selectDistro .= qq~</select>~;
	
	# my @lsKeys = split(/\n/, `ls $VAR{keyPath}`);
	# my $selectKeyPair = qq~<select name="keypair" style="width: 200px;">~;
	# for my $key ( @lsKeys ) {
		# $selectKeyPair .= qq~<option value="$key">$key</option>\n~;
	# }
	# $selectKeyPair .= qq~</select>~;
	
	
	$html .= qq~
	<div id="miquiloniToolTip"></div>
		<script>
			function checkMemory(maxMem) {
				var x, text;
				x = document.getElementById("memory").value;
				x = x.replace(/[MG]\$/, "");
				
				if (isNaN(x) || x > maxMem || x == null || x == "") {
					text = "Memory value is not valid";
					document.getElementById("errorMem").innerHTML = text;
				} else {
					document.getElementById("errorMem").innerHTML = '';
				}
			}
			function checkVolumeSize(maxSize) {
				var x, text;
				x = document.getElementById("volumeSize").value;
				x = x.replace(/[MGT]\$/, "");
				
				if (isNaN(x) || x > maxSize || x == null || x == "") {
					text = "Volume Size value is missing or not valid";
					document.getElementById("errorVolSize").innerHTML = text;
				} else {
					document.getElementById("errorVolSize").innerHTML = '';
				}
			}
			function checkContainerName() {
				var x, text;
				x = document.getElementById("containerName").value;
				if (x == null || x == "" || x.length < 4) {
					text = "Container Name is missing or too short";
					document.getElementById("errorContainer").innerHTML = text;
				} else {
					document.getElementById("errorContainer").innerHTML = '';
				}
			}
			function checkHostName() {
				var x, text;
				x = document.getElementById("hostname").value;
				if (x == null || x == "" || x.length < 4) {
					text = "Host Name is missing or too short";
					document.getElementById("errorHostname").innerHTML = text;
				} else {
					document.getElementById("errorHostname").innerHTML = '';
				}
			}
			function displayNetConf(sel) {
				var elms = document.querySelectorAll("[id='netwConfig']");
				for(var i = 0; i < elms.length; i++) {
					if (sel.value == "dhcp") {
						elms[i].style.display = 'none';
					} else {
						elms[i].style.display = 'table-row';
					}
				}
			}
			
			function openModal(modalId) {
				document.getElementById(modalId).style.display = "block";
			}
			function closeModal(modalId) {
				document.getElementById(modalId).style.display = "none";
			}
			function goToLink(html_link, targetLink) {
				window.open(html_link, targetLink);
			}
			function openModalRedirect(modalId, htmlink, targetLink) {
				document.getElementById(modalId).style.display = "block";
				window.open(htmlink, targetLink);
			}
			function openModalCloseAndRedirect(modalIdToOpen, modalIdToClose, htmlink, targetLink) {
				document.getElementById(modalIdToClose).style.display = "none";
				document.getElementById(modalIdToOpen).style.display = "block";
				window.open(htmlink, targetLink);
			}
		</script>
		
		
		<form name="theform" method="get" action="index.cgi">
		<input type="hidden" name="mod" value="migration">
		<input type="hidden" name="submod" value="configure_container">
		<input type="hidden" name="originIdContainer" value="$input{originIdContainer}">
		<input type="hidden" name="originIdServer" value="$originIdServer">
		<input type="hidden" name="targetIdServer" value="$targetIdServer">
		
		<table cellpadding="0" cellspacing="0" class="formTitle">
		<tr><td style="font-size: 12px">$MSG{Selecting_hardware_base_of} <b>$targetHostName</b></td></tr>
		</table>
		
		<table cellpadding="0" cellspacing="0" class="form">
		
		
		<tr><td align="right" width="30%">$MSG{Memory} (${memory}M $MSG{Free}): </td><td width="70%"><input onBlur="checkMemory($memory);" type="text" name="memory" id="memory" value="${memory}M">
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{M_or_G_for_memory_unity_Default_is_M_if_no_Memory_unity_1024M_1G_or_1024_are_the_same_thing}', '', '', '');" onMouseout="hideToolTip();" />
		<p id="errorMem" style="color: #FF0000"></p></td></tr>
		
		<tr><td align="right" width="30%">CPU's ($cpus $MSG{Free}): </td><td width="70%">
		$selectCPUs 
		<input type="radio" name="fractcpu" value="whole" checked> $MSG{I_want_whole_CPUs}
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{If_you_want_one_or_more_whole_CPUs}', '', '', '');" onMouseout="hideToolTip();" />
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Percent_CPU}: </td><td width="70%">
		$selectPercentCpu
		<input type="radio" name="fractcpu" value="fraction"> $MSG{I_prefer_a_fraction_of_CPU}
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{If_you_want_a_fraction_of_one_CPUs}', '', '', '');" onMouseout="hideToolTip();" />
		</td></tr>
		
		<tr><td align="right" width="30%">VG: </td><td width="70%">
		$vgSelect
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Volume_Size}: </td><td width="70%">
		<input type="text" onBlur="checkVolumeSize(this.value);" name="volumeSize" value="" id="volumeSize">
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{M_G_or_T_for_volume_size_unity_Default_is_G_if_no_Size_unity_1024M_1G_or_1024_are_the_same_thing}', '', '', '');" onMouseout="hideToolTip();" />
		<p id="errorVolSize" style="color: #FF0000"></p></td></tr>
		
		
		
		<tr><td align="right" width="30%">$MSG{Target_LXC_Server_Password}: </td><td width="70%"><input type="password" name="targetServerPassword" value=""></td></tr>
		
		
		</table>
		
		<table cellpadding="0" cellspacing="0" class="formFooter">
		<tr><td>
		<button class="blueLightButton" onClick="return openModal('myModalRedirectStart');">$MSG{Migrate_Container}</button> &nbsp; 
		<a href="index.cgi?mod=migration&originIdContainer=$input{originIdContainer}" class="greyButton" target="_top" >Back to start</a></td></tr>
		
		</table>
		
		</form>
		<br>
		
		<div id="myModalRedirectStart" class="confirm"><div class="confirm-content">
			$MSG{Alert}<hr class="confirm-header">
			$MSG{Container_is_being_migrating_now}.<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
		</div></div>
	~;
}


sub getCPU {
	my ($idServer, $fractcpu, $cpus, $percentcpu) = @_;
	
	connected();
	my $sth = $dbh->prepare("SELECT cpuId, COUNT(cpuQuarter) FROM cpus WHERE idServer = '$idServer' AND idContainer IS NULL GROUP BY cpuId");
	$sth->execute();
	my $proc = $sth->fetchall_arrayref;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	if ( $fractcpu eq 'whole' ) {
		my $cpulist;
		my $cnt = 1;
		for my $i ( 0 .. $#{$proc} ) {
			if ( $proc->[$i][1] == 4 ) {
				$cpulist .= $proc->[$i][0] . ',';
				if ( $cpus == $cnt ) {
					$cpulist =~ s/\,$//;
					return ($cpulist, '1,2,3,4');
				}
				$cnt++;
			}
		}
	} elsif ( $fractcpu eq 'fraction' ) {
		for my $i ( 0 .. $#{$proc} ) {
			if ( $proc->[$i][1] * 25 >= $percentcpu ) {
				connected();
				my $sth = $dbh->prepare("SELECT cpuQuarter FROM cpus WHERE idServer = '$idServer' AND idContainer IS NULL AND cpuId = '$proc->[$i][0]'");
				$sth->execute();
				my $quarter = $sth->fetchall_arrayref;
				$sth->finish;
				$dbh->disconnect if ($dbh);
				
				my $cnt = 25;
				my $quarterslist;
				for my $j ( 0 .. $#{$quarter} ) {
					$quarterslist .= $quarter->[$j][0] . ',';
					if ( $percentcpu == $cnt ) {
						$quarterslist =~ s/\,$//;
						return ($proc->[$i][0], $quarterslist);
					}
					$cnt += 25;
				}
			}
		}
	}
}



if ( $input{submod} eq 'configure_container' ) {
	my ($distro, $release, $architecture) = split(/\-/, $input{originDistro});
	
	$input{percentcpu} = $input{fractcpu} eq 'whole' ? '100' : $input{percentcpu};
	
	my ($cpulist, $quarters) = getCPU($input{targetIdServer}, $input{fractcpu}, $input{cpus}, $input{percentcpu});
	
	connected();
	my $sth = $dbh->prepare("SELECT hostName, IPv4, privateKey FROM lxcservers WHERE idServer = '$input{originIdServer}'");
	$sth->execute();
	my ($originalHostName, $originalHost, $originalPrivateKey) = $sth->fetchrow_array;
	$sth->finish;
	
	my $sth1 = $dbh->prepare("SELECT IPv4, privateKey FROM lxcservers WHERE idServer = '$input{targetIdServer}'");
	$sth1->execute();
	my ($targetHost, $targetPrivateKey) = $sth1->fetchrow_array;
	$sth1->finish;
	$dbh->disconnect if ($dbh);
	
	my $sth2 = $dbh->prepare("SELECT containerName FROM containers WHERE idContainer = '$input{originIdContainer}'");
	$sth2->execute();
	my ($originContainerName) = $sth2->fetchrow_array;
	$sth2->finish;
	$dbh->disconnect if ($dbh);
	
	$input{containerName} =~ s/\s/\_/g;
	$input{hostname} =~ s/\s/\_/g;
	$input{memory} = $input{memory}.'M' unless $input{memory} =~ /[MG]$/;
	$input{volumeSize} = $input{volumeSize}.'G' unless $input{volumeSize} =~ /[MG]$/;
	
	# $html .= qq~
	# <br>
	# \$input{cpus} = $input{cpus}<br>
	# \$input{fractcpu} = $input{fractcpu}<br>
	# \$input{percentcpu} = $input{percentcpu}<br>
	# \$cpulist = $cpulist<br>
	# \$quarters = $quarters<br>
	# \$input{memory} = $input{memory}<br>
	# \$input{protocolEth0} = $input{protocolEth0}<br>
	
	# \$input{originIdContainer} = $input{originIdContainer}<br>
	# \$originContainerName = $originContainerName<br>
	
	# \$input{originIdServer} = $input{originIdServer}<br>
	# \$originalHost = $originalHost<br>
	# \$originalPrivateKey = $originalPrivateKey<br>
	
	# \$input{targetIdServer} = $input{targetIdServer}<br>
	# \$targetHost = $targetHost<br>
	
	# \$input{originKeyPair} = $input{originKeyPair}<br>
	
	# \$input{targetServerPassword} = $input{targetServerPassword}<br>
	
	# lvcreate: $input{volumeSize}, "lv$input{containerName}", $input{vg}<br>
	# <br>
	# Name		=> '$originContainerName',<br>
	# remoteHost	=> '$targetHost',<br>
	# passwd		=> '$input{targetServerPassword}',<br>
	# ~;
	
	my $ok = 1;
	unless ( $input{memory} ) {
		$html .= qq~<font color="#BB0000"><b>$MSG{Memory_value_is_missing}</b></font>. $MSG{Please} <a href="javascript:history.back();">$MSG{back}</a> $MSG{and_correct_the_field}<br /><br />~; $ok = 0;
	}
	unless ( $input{memory} =~ /M$/) {
		$html .= qq~<font color="#BB0000"><b>$MSG{Memory_value_is_not_correct}</b></font>. $MSG{Please} <a href="javascript:history.back();">$MSG{back}</a> $MSG{and_correct_the_field}<br /><br />~; $ok = 0;
	}
	unless ( $input{vg} ) {
		$html .= qq~<font color="#BB0000"><b>$MSG{Volume_Group_is_missing}</b></font>. $MSG{Please} <a href="javascript:history.back();">$MSG{back}</a> $MSG{and_correct_the_field}<br/><br/>~; $ok = 0;
	}
	unless ( $input{volumeSize} ) {
		$html .= qq~<font color="#BB0000"><b>$MSG{Volume_Size_is_missing}</b></font>. $MSG{Please} <a href="javascript:history.back();">$MSG{back}</a> $MSG{and_correct_the_field}<br /><br />~; $ok = 0;
	}
	unless ( $input{volumeSize} =~ /(M|G)$/ ) {
		$html .= qq~<font color="#BB0000"><b>$MSG{Volume_Size_does_not_have_the_correct_format}</b></font>. $MSG{Please} <a href="javascript:history.back();">$MSG{back}</a> $MSG{and_correct_the_field}<br /><br />~; $ok = 0;
	}
	
	if ( $ok ) {
		use LVM::LVMWrapper;
		my $lvm = LVM::LVMWrapper->new($targetHost, $VAR{keyPath} . '/' . $targetPrivateKey);
		my $lvcreate = $lvm->lvcreate($input{volumeSize}, "lv$originContainerName", $input{vg});
		my $mkfsxfs = $lvm->mkfsxfs($input{vg}, "lv$originContainerName");
		my $lvmount = $lvm->lvmount($originContainerName, $input{vg}, 'lv'.$originContainerName);
		sleep 1;
		
		unless ( $lvmount ) {
			use LXC::LXCWrapper;
			
			my $lxc = LXC::LXCWrapper->new($originalHost, $VAR{keyPath} . '/' . $originalPrivateKey, 'root', 600);
			
			my $response = $lxc->remoteCopy({
				Name		=> $originContainerName,
				remoteHost	=> $targetHost,
				passwd		=> $input{targetServerPassword},
			});
			
			##use Data::Dumper;
			##$html .= "<br>\$response = " . Dumper($response) . "<br>";
			
			my $lxc1 = LXC::LXCWrapper->new($targetHost, $VAR{keyPath} . '/' . $targetPrivateKey);
			
			$response = $lxc1->update_migrated({
				Name		=> $originContainerName,
				memory		=> $input{memory},
				cpu			=> $cpulist,
				percentCpu	=> $input{percentcpu}
			});
			
			connected();
			my $sth = $dbh->prepare("SELECT '$input{targetIdServer}', containerName, hostName, distribution, release_, architecture, '$input{vg}', 'lv$originContainerName', '$input{volumeSize}', bootProto, ipAddr, netmask, 
			gateway, broadcast, network, '$input{memory}', '$cpulist', '$input{percentcpu}', keyPair, startAuto, startDelay, shortDescription, creatorId, ownerId FROM containers WHERE idContainer = '$input{originIdContainer}'");
			$sth->execute();
			my @oldRec = $sth->fetchrow_array;
			$sth->finish;
			
			my $fieldList;
			foreach my $field ( @oldRec ) {
				$fieldList .= qq~'$field', ~;
			}
			$fieldList =~ s/, $//;
			
			my $insert_string = "INSERT INTO containers (idServer, containerName, hostName, distribution, release_, architecture, vgName, lvName, lvSize, bootProto, ipAddr, netmask, 
			gateway, broadcast, network, memory, cpu, percentCpu, keyPair, startAuto, startDelay, shortDescription, creatorId, ownerId) VALUES ($fieldList)";
			$sth = $dbh->prepare("$insert_string");
			$sth->execute();
			$sth->finish;
			
			my $sth = $dbh->prepare("SELECT idContainer FROM containers WHERE containerName = '$oldRec[1]' AND idServer = '$input{targetIdServer}'");
			$sth->execute();
			my ($idContainer) = $sth->fetchrow_array;
			$sth->finish;
			
			foreach my $cpuId ( split(/\,/, $cpulist) ) {
				foreach my $cpuQuarter ( split(/\,/, $quarters) ) {
					my $sth = $dbh->prepare("UPDATE cpus SET idContainer='$idContainer' WHERE idServer='$input{targetIdServer}' AND cpuId='$cpuId' AND cpuQuarter='$cpuQuarter'");
					$sth->execute();
					$sth->finish;
				}
			}
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("MIGRATE:Container:originalHost=$originalHost;originContainerName=$originContainerName;targetHost=$targetHost;");
			
			my $update_string = "UPDATE containers SET locked = '1' WHERE idContainer = '$input{originIdContainer}' AND idServer = '$input{originIdServer}'";
			my $sth1 = $dbh->prepare("$update_string");
			$sth1->execute();
			$sth1->finish;
			
			$dbh->disconnect if $dbh;
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("LOCKED:Container:originalHost=$originalHost;originContainerName=$originContainerName");
			
			my @containers = ($oldRec[1]);
			##use LXC::LXCWrapper;
			my $lxc2 = LXC::LXCWrapper->new($targetHost, $VAR{keyPath} . '/' . $targetPrivateKey);
			$response = $lxc2->start(\@containers);
			
			print "Location: index.cgi?mod=containers\n\n";
		}
	}
}

return $html;
1;
