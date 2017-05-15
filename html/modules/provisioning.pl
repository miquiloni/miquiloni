%MSG = loadLang('Provisioning');

my $html;
$html .= qq~<div class="contentTitle">$MSG{Provisioning}</div>~ unless $input{'shtl'};

unless ( $input{submod} ) {
	connected();
	my $sth = $dbh->prepare("SELECT * FROM sector");
	$sth->execute();
	my $sectors = $sth->fetchall_arrayref;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	my $sectorSeleted;
	my $optionSectors = qq~<option value=""> - $MSG{Please_Select} - </option>\n~;
	for my $i ( 0 .. $#{$sectors} ) {
		my $selected = $input{idSector} eq $sectors->[$i][0] ? 'selected' : '';
		$sectorSeleted = $sectors->[$i][1] if $selected;
		$optionSectors .= qq~<option value="$sectors->[$i][0]" $selected>$sectors->[$i][1]</option>\n~;
	}
	$html .= qq~
		<form method="get" action="index.cgi">
		<input type="hidden" name="mod" value="provisioning">
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
		            { field: 'hostname', caption: 'Hostname', size: '100px', sortable: true, searchable: true },
		            { field: 'freemem', caption: '$MSG{Free_Memory}', size: '200px', sortable: true },
		            { field: 'freecpus', caption: '$MSG{Free_CPUs}', size: '200px', sortable: true },
		            { field: 'cpumake', caption: '$MSG{CPU_Make}', size: '100', sortable: true },
		            { field: 'cpumodel', caption: '$MSG{CPU_Model}', size: '100', sortable: true },
		            { field: 'cpuspeed', caption: '$MSG{CPU_Speed}', size: '100', sortable: true },
		        ],
		        records: [
		        ~;
		        
				foreach my $key ( keys %SRV ) {
					my $freemem = $SRV{$key}{data}[1] - $SRV{$key}{utilizedmemory};
					my $freecpus = $SRV{$key}{data}[2] - $SRV{$key}{utilizedcpus};
					my $freememColor = $freemem >= 1 ? '#00BB00' : '#BB0000';
					my $freecpusColor = $freecpus >= 0.25 ? '#00BB00' : '#BB0000';
					
					$html .= qq~{
					recid: '$key-$freemem-$freecpus',
					hostname: '$SRV{$key}{data}[0]',
					freemem: '<font color="$freememColor"><b>$freemem</b></font> of $SRV{$key}{data}[1]',
					freecpus: '<font color="$freecpusColor"><b>$freecpus</b></font> of $SRV{$key}{data}[2]',
					cpumake: '$SRV{$key}{data}[3]',
					cpumodel: '$SRV{$key}{data}[4]',
					cpuspeed: '$SRV{$key}{data}[5]',
					},~ if $SRV{$key}{data}[0];
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
		                    var html_link = 'index.cgi?mod=provisioning&submod=select_storage&recid='+recid;
		                    window.open(html_link, '_top');
		                }
		            }
		        }
		    });
		});
		</script>
		~;
		
		# foreach my $key ( keys %SRV ) {
			# $html .= qq~ID $key:<br />~;
			# $html .= qq~hostname: $SRV{$key}{data}[0]<br />~;
			# ##$html .= qq~total memory: $SRV{$key}{data}[1]<br />~;
			# my $freemem = $SRV{$key}{data}[1] - $SRV{$key}{utilizedmemory};
			# $html .= qq~free memory: $freemem of $SRV{$key}{data}[1]<br />~;
			# ##$html .= qq~total cpus: $SRV{$key}{data}[2]<br />~;
			# my $freecpus = $SRV{$key}{data}[2] - $SRV{$key}{utilizedcpus};
			# $html .= qq~free cpus: $freecpus of $SRV{$key}{data}[2]<br />~;
			
			# $html .= qq~cpumake: $SRV{$key}{data}[3]<br />~;
			# $html .= qq~cpumodel: $SRV{$key}{data}[4]<br />~;
			# $html .= qq~cpuspeed: $SRV{$key}{data}[5]<br />~;
			# ##$html .= qq~sectorname: $SRV{$key}{data}[6]<br />~;
			# ##$html .= qq~utilizedmemory: $SRV{$key}{utilizedmemory}<br />~;
			# ##$html .= qq~utilizedcpus: $SRV{$key}{utilizedcpus}<br />~;
		# }
	}
}

if ( $input{submod} eq 'select_storage' ) {
	my ($idServer, $memory, $cpus) = split(/\-/, $input{recid});
	##$html .= qq~<b>Variable \$cpus:$cpus</b><br><br>~;
	$html .= qq~
		<script>
		function setVolumeSize(val){
			document.getElementById("volumeSize").value=val;
		}
		</script>
	~;
	
	
	use LVM::LVMWrapper;
	
	connected();
	my $sth = $dbh->prepare("SELECT hostName, IPv4, privateKey FROM lxcservers WHERE idServer = '$idServer'");
	$sth->execute();
	my ($hostName, $host, $privateKey) = $sth->fetchrow_array;
	$sth->finish;
	
	$sth = $dbh->prepare("SELECT distroData, showData FROM distros WHERE active = '1'");
	$sth->execute();
	my $distro = $sth->fetchall_arrayref;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	my $lvm = LVM::LVMWrapper->new($host, $VAR{keyPath} . '/' . $privateKey);
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
			
			$vgSelect .= qq~$key <input type="radio" name="vg" id="vg" onFocus="setVolumeSize('$response->{$key}[1]')" value="$key" >  ($response->{$key}[1] $MSG{Free_of} $response->{$key}[0])<br/>~;
			# $chckd = undef;
		}
	} else {
		$vgSelect .= qq~<font color="#EE0000">$MSG{I_cannot_read_the_list_of_VGs_Please_go_back_and_try_again}</font><br/>~;
	}
	
	my ($intcpu, $percentcpu) = split(/\./, $cpus);
	# $cpus=~/([\d]+)\.([\d]+)/;
	# my $intcpu = $1;
	# my $percentcpu = $2;
	##$html .= qq~<b>Variables \$intcpu:$intcpu - \$percentcpu:$percentcpu</b><br><br>~;
	
	$percentcpu = '50' if $percentcpu eq '5';
	
	# my $selectPercentCpu;
	$selectPercentCpu .= qq~<select name="percentcpu" style="width: 100px;">~;
	if ( $intcpu >= 1 ) {
		foreach my $prcnt ( 25, 50, 75 ) {
			my $selected = $percentcpu eq $prcnt ? 'selected' : '';
			$selectPercentCpu .= qq~<option value="$prcnt" $selected>$prcnt \%</option>~;
		}
		$selectPercentCpu .= qq~</select>~;
	} else {
		if ( $percentcpu ) {
			my $rest = 100 * ".$percentcpu";
			foreach my $prcnt ( 25, 50, 75 ) {
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
		$selectCPUs .= qq~<option value="$qtyCPUs">$qtyCPUs</option>\n~;
	}
	$selectCPUs .= qq~</select>~;
	
	my $selectDistro = qq~<select name="distro" style="width: 200px;">~;
	for my $i ( 0 .. $#{$distro} ) {
		$selectDistro .= qq~<option value="$distro->[$i][0]">$distro->[$i][1]</option>\n~;
	}
	$selectDistro .= qq~</select>~;
	
	my @lsKeys = split(/\n/, `ls $VAR{keyPath} | sed 's/\.pub//' | sort -u`);
	my $selectKeyPair = qq~<select name="keypair" style="width: 200px;">~;
	for my $key ( @lsKeys ) {
		my $keyName = $key;
		$keyName =~ s/\.key$//;
		$selectKeyPair .= qq~<option value="$key">$keyName</option>\n~ ;
	}
	$selectKeyPair .= qq~</select>~;
	
	
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
					if (sel.value == "static") {
						elms[i].style.display = 'table-row';
					} else {
						elms[i].style.display = 'none';
					}
					
					//if (sel.value == "dhcp") {
						//elms[i].style.display = 'none';
					//} else {
						//elms[i].style.display = 'table-row';
					//}
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
		<input type="hidden" name="mod" value="provisioning">
		<input type="hidden" name="submod" value="configure_container">
		<input type="hidden" name="idServer" value="$idServer">
		
		<table cellpadding="0" cellspacing="0" class="formTitle">
		<tr><td style="font-size: 12px">$MSG{Selecting_hardware_base_from} <b>$hostName</b></td></tr>
		</table>
		
		<table cellpadding="0" cellspacing="0" class="form">
		
		
		<tr><td align="right" width="30%">$MSG{Memory} (${memory}M $MSG{Free}): </td><td width="70%"><input onBlur="checkMemory($memory);" type="text" name="memory" id="memory" value="${memory}M">
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{M_for_memory_unity_MBytes_Default_is_M_if_no_Memory_unity_1024M_instead_of_1G_1024_and_1024M_are_the_same_thing}', '', '', '');" onMouseout="hideToolTip();" />
		<p id="errorMem" style="color: #FF0000"></p></td></tr>
		
		<tr><td align="right" width="30%">CPU's ($cpus $MSG{Free}): </td><td width="70%">
		$selectCPUs 
		<input type="radio" name="fractcpu" value="whole"> $MSG{I_want_whole_CPUs}
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{If_you_want_one_or_more_whole_CPUs}', '', '', '');" onMouseout="hideToolTip();" />
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Percent_CPU}: </td><td width="70%">
		$selectPercentCpu
		<input type="radio" name="fractcpu" value="fraction" checked> $MSG{I_prefer_a_fraction_of_CPU}
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{If_you_want_a_fraction_of_one_CPUs}', '', '', '');" onMouseout="hideToolTip();" />
		</td></tr>
		
		<tr><td align="right" width="30%">VG: </td><td width="70%">
		$vgSelect
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Volume_Size}: </td><td width="70%">
		<input type="text" onBlur="checkVolumeSize(this.value);" name="volumeSize" value="" id="volumeSize">
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{M_G_or_T_for_volume_size_unity_Default_is_G_if_no_Size_unity_1024M_1G_or_1024_are_the_same_thing}', '', '', '');" onMouseout="hideToolTip();" />
		<p id="errorVolSize" style="color: #FF0000"></p></td></tr>
		
		<tr><td align="right" width="30%">$MSG{Container_Name}: </td><td width="70%"><input onBlur="checkContainerName();" type="text" name="containerName" id="containerName" maxlength="20"><p id="errorContainer" style="color: #FF0000"></p></td></tr>
		
		<tr><td align="right" width="30%">Hostname: </td><td width="70%"><input onBlur="checkHostName();" type="text" name="hostname" id="hostname" maxlength="20"><p id="errorHostname" style="color: #FF0000"></p</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Distro_Release_Arch}: </td><td width="70%">
		$selectDistro
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Start_Auto_at_LXC_Server_Start}: </td><td width="70%">
		<select name="startAuto"><option value="1">$MSG{Yes}</option><option value="0">$MSG{No}</option></select>
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{If_you_want_start_this_container_at_moment_of_start_the_LXC_Server_select_Yes}', '', '', '');" onMouseout="hideToolTip();" />
		</td></tr>
		<tr><td align="right" width="30%">$MSG{Start_Delay_after_LXC_Server_Start}: </td><td width="70%"><input type="text" name="startDelay" value="5" style="width: 20px;"> $MSG{Seconds}</td></tr>
		
		
		<tr><td align="right" width="30%">$MSG{Interfase_eth0_protocol}: </td><td width="70%">
		<select onChange="displayNetConf(this);" id="protocolEth0" name="protocolEth0">
		<option value="dhcp" selected>DHCP</option>
		<option value="static">Static</option>
		</select>
		<img src="../images/help-32x32.png" width="20" onMouseOver="showToolTip('$MSG{We_strongly_recommend_that_you_select_DHCP_at_startup_and_then_change_it_to_STATIC_if_you_wish}', '', '', '');" onMouseout="hideToolTip();" />
		</td></tr>
		
		<tr id="netwConfig" style="display: none;"><td align="right" width="30%">$MSG{IP_Address_IPv4}: </td><td width="70%"><input type="text" name="ipAddr"></td></tr>
		<tr id="netwConfig" style="display: none;"><td align="right" width="30%">$MSG{Gateway}: </td><td width="70%"><input type="text" name="gateway"></td></tr>
		<tr id="netwConfig" style="display: none;"><td align="right" width="30%">$MSG{Netmask}: </td><td width="70%"><input type="text" name="netmask"></td></tr>
		<tr id="netwConfig" style="display: none;"><td align="right" width="30%">$MSG{Network}: </td><td width="70%"><input type="text" name="network"></td></tr>
		<tr id="netwConfig" style="display: none;"><td align="right" width="30%">Broadcast: </td><td width="70%"><input type="text" name="broadcast"></td></tr>
		
		<tr><td align="right" width="30%">$MSG{Key}: </td><td width="70%">
		$selectKeyPair
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Short_Description}: </td><td width="70%"><input type="text" name="shortDescription" style="width: 400px;"></td></tr>
		
		</table>
		
		<table cellpadding="0" cellspacing="0" class="formFooter">
		<tr><td>
		<button class="blueLightButton" onClick="return openModal('myModalRedirectStart');">$MSG{Launch_Container}</button> &nbsp; 
		<a href="index.cgi?mod=provisioning" class="greyButton" target="_top" >$MSG{Back_to_start}</a></td></tr>
		
		</table>
		
		</form>
		<br>
		
		<div id="myModalRedirectStart" class="confirm"><div class="confirm-content">
			$MSG{Alert}<hr class="confirm-header">
			$MSG{Container_is_creating_now}<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
		</div></div>
	~;
}



##SELECT cpuId, COUNT(cpuCuarter) FROM cpus WHERE idServer = '1' AND idContainer IS NULL GROUP BY cpuId
##SELECT cpuQuarter FROM cpus WHERE idServer = '1' AND idContainer IS NULL AND cpuId = '0'
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
	my ($distro, $release, $architecture) = split(/\-/, $input{distro});
	my $release2sql = $release;
	$release =~ s/\.//g;
	
	$input{percentcpu} = $input{fractcpu} eq 'whole' ? '100' : $input{percentcpu};
	
	my ($cpulist, $quarters) = getCPU($input{idServer}, $input{fractcpu}, $input{cpus}, $input{percentcpu});
	
	connected();
	my $sth = $dbh->prepare("SELECT hostName, IPv4, privateKey FROM lxcservers WHERE idServer = '$input{idServer}'");
	$sth->execute();
	my ($hostName, $host, $privateKey) = $sth->fetchrow_array;
	$sth->finish;
	
	$sth = $dbh->prepare("SELECT containerName, hostName FROM containers WHERE containerName = '$input{containerName}' OR hostName = '$input{hostname}' AND idServer = '$input{idServer}'");
	$sth->execute();
	my ($TESTcontainerName, $TESThostName) = $sth->fetchrow_array;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	$input{containerName} =~ s/\s/\_/g;
	$input{hostname} =~ s/\s/\_/g;
	$input{memory} = $input{memory}.'M' unless $input{memory} =~ /[MG]$/;
	$input{volumeSize} = $input{volumeSize}.'G' unless $input{volumeSize} =~ /[MG]$/;
	
	sleep 1;
	
	# $html .= qq~
	# <br>
	# \$input{cpus} = $input{cpus}<br>
	# \$input{fractcpu} = $input{fractcpu}<br>
	# \$input{percentcpu} = $input{percentcpu}<br>
	# \$cpulist = $cpulist<br>
	# \$quarters = $quarters<br>
	# \$input{containerName} = $input{containerName}<br>
	# \$input{hostname} = $input{hostname}<br>
	# \$distro = $distro<br>
	# \$release = $release<br>
	# \$architecture = $architecture<br>
	# \$input{memory} = $input{memory}<br>
	# \$input{protocolEth0} = $input{protocolEth0}<br>
	# \$input{idServer} = $input{idServer}<br>
	# Keypair = $input{keypair}<br>
	# lvcreate: $input{volumeSize}, "lv$input{containerName}", $input{vg}<br>
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
	
	unless ( $input{containerName} ) {
		$html .= qq~<font color="#BB0000"><b>$MSG{Container_Name_is_missing}</b></font>. $MSG{Please} <a href="javascript:history.back();">$MSG{back}</a> $MSG{and_correct_the_field}<br /><br />~; $ok = 0;
	}
	unless ( $input{containerName} =~ /^[a-zA-Z0-9\_\-\.]+$/ ) {
		$html .= qq~<font color="#BB0000"><b>$MSG{Container_Name_has_invalid_characters}</b></font>. $MSG{Please} <a href="javascript:history.back();">$MSG{back}</a> $MSG{and_correct_the_field}<br /><br />~; $ok = 0;
	}
	if ( $input{containerName} eq $TESTcontainerName ) {
		$html .= qq~<font color="#BB0000"><b>$MSG{Container_Name_already_exists}</b></font>. $MSG{Please} <a href="javascript:history.back();">$MSG{back}</a> $MSG{and_correct_the_field}<br /><br />~; $ok = 0;
	}
	
	unless ( $input{hostname} ) {
		$html .= qq~<font color="#BB0000"><b>$MSG{Host_Name_is_missing}</b></font>. $MSG{Please} <a href="javascript:history.back();">$MSG{back}</a> $MSG{and_correct_the_field}<br /><br />~; $ok = 0;
	}
	unless ( $input{hostname} =~ /^[a-zA-Z0-9\_\-\.]+$/ ) {
		$html .= qq~<font color="#BB0000"><b>$MSG{Host_Name_has_invalid_characters}</b></font>. $MSG{Please} <a href="javascript:history.back();">$MSG{back}</a> $MSG{and_correct_the_field}<br /><br />~; $ok = 0;
	}
	if ( $input{hostname} eq $TESThostName ) {
		$html .= qq~<font color="#BB0000"><b>$MSG{Host_Name_already_exists}</b></font>. $MSG{Please} <a href="javascript:history.back();">$MSG{back}</a> $MSG{and_correct_the_field}<br /><br />~; $ok = 0;
	}
	
	if ( $ok ) {
		use LVM::LVMWrapper;
		my $lvm = LVM::LVMWrapper->new($host, $VAR{keyPath} . '/' . $privateKey);
		my $lvcreate = $lvm->lvcreate($input{volumeSize}, "lv$input{containerName}", $input{vg});
		my $mkfsxfs = $lvm->mkfsxfs($input{vg}, "lv$input{containerName}");
		my $lvmount = $lvm->lvmount($input{containerName}, $input{vg}, 'lv'.$input{containerName});
		sleep 1;
		
		unless ( $mkfsxfs or $lvmount ) {
			use LXC::LXCWrapper;
			my $lxc = LXC::LXCWrapper->new($host, $VAR{keyPath} . '/' . $privateKey);
			
			my $response = $lxc->create({
				Name		=> $input{containerName},
				hostname	=> $input{hostname},
				Distro		=> $distro,
				Release		=> $release,
				Arch		=> $architecture,
				memory		=> $input{memory},
				cpu			=> $cpulist,
				percentCpu	=> $input{percentcpu},
				startAuto	=> $input{startAuto},
				startDelay	=> $input{startDelay},
				TimeOut		=> 3600,
				iface		=> 'eth0',
				proto		=> $input{protocolEth0},
				ipAddr		=> $input{ipAddr},
				gateway		=> $input{gateway},
				netmask		=> $input{netmask},
				network		=> $input{network},
				broadcast	=> $input{broadcast},
				keypair		=> $VAR{keyPath} . '/' . $input{keypair}
			});
			##use Data::Dumper;
			##$html .= "<br>\$response = " . Dumper($response) . "<br>";
			
			connected();
			my $sth = $dbh->prepare("SELECT idUser FROM users WHERE username = '$username'");
			$sth->execute();
			my ($idUser) = $sth->fetchrow_array;
			$sth->finish;
			
			my $insert_string = "INSERT INTO containers (idServer, containerName, hostName, distribution, release_, architecture, vgName, lvName, lvSize, bootProto, ipAddr, netmask, 
			gateway, broadcast, network, memory, cpu, percentCpu, keyPair, startAuto, startDelay, shortDescription, creatorId, ownerId) VALUES (
			'$input{idServer}',
			'$input{containerName}',
			'$input{hostname}',
			'$distro',
			'$release2sql',
			'$architecture',
			'$input{vg}',
			'lv$input{containerName}',
			'$input{volumeSize}',
			'$input{protocolEth0}',
			'$input{ipAddr}',
			'$input{netmask}',
			'$input{gateway}',
			'$input{broadcast}',
			'$input{network}',
			'$input{memory}',
			'$cpulist',
			'$input{percentcpu}',
			'$input{keypair}',
			'$input{startAuto}',
			'$input{startDelay}',
			'$input{shortDescription}',
			'$idUser',
			'$idUser')";
			$sth = $dbh->prepare("$insert_string");
			$sth->execute();
			$sth->finish;
			
			my $sth = $dbh->prepare("SELECT idContainer FROM containers WHERE containerName = '$input{containerName}' AND idServer = '$input{idServer}'");
			$sth->execute();
			my ($idContainer) = $sth->fetchrow_array;
			$sth->finish;
			
			foreach my $cpuId ( split(/\,/, $cpulist) ) {
				foreach my $cpuQuarter ( split(/\,/, $quarters) ) {
					my $sth = $dbh->prepare("UPDATE cpus SET idContainer='$idContainer' WHERE idServer='$input{idServer}' AND cpuId='$cpuId' AND cpuQuarter='$cpuQuarter'");
					$sth->execute();
					$sth->finish;
				}
			}
			$dbh->disconnect if $dbh;
			
			sleep 1;
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("PROVISIONING:Container:idContainer=$idContainer;Name=$input{containerName};hostname=$input{hostname};Distro=$distro;Release=$release;Arch=$architecture;memory=$input{memory};cpu=$cpulist;percentCpu=$input{percentcpu};startAuto=$input{startAuto};startDelay=$input{startDelay};proto=$input{protocolEth0};ipAddr=$input{ipAddr};gateway=$input{gateway};netmask=$input{netmask};network=$input{network};broadcast=$input{broadcast};keypair=$input{keypair}");
			
			my @containers = ($input{containerName});
			##use LXC::LXCWrapper;
			my $lxc = LXC::LXCWrapper->new($host, $VAR{keyPath} . '/' . $privateKey);
			my $response = $lxc->start(\@containers);
			
			print "Location: index.cgi?mod=containers\n\n";
		}
		else {
			$response=~ s/\n/\;/g;
			$lvcreate=~ s/\n/\;/g;
			$mkfsxfs=~ s/\n/\;/g;
			$lvmount=~ s/\n/\;/g;
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("FAIL-PROVISIONING:Container:Name=$input{containerName};LXCWrapperResponse=$response;LVMResponse=$lvcreate;MKFSxfsResponse=$mkfsxfs;LVMountResponse=$lvmount");
			
			my $lvm = LVM::LVMWrapper->new($host, $VAR{keyPath} . '/' . $privateKey);
			my $responseUmount = $lvm->lvremove($input{vg}, "lv$input{containerName}", $input{containerName});
			
			$log->Log("FAIL-REMOVE-LVM:RemoveLVM:Name=$input{containerName};LVMResponse=$responseUmount") if $responseUmount;
			
			##$html .= qq~
			##\$response=$response<br>
			##\$lvcreate=$lvcreate<br>
			##\$mkfsxfs=$mkfsxfs<br>
			##\$lvmount=$lvmount<br>
			##~;
			print "Location: index.cgi?mod=containers\n\n";
		}
		##$html .= qq~Aquí no debe llegar~;
	}
}








return $html;
1;
