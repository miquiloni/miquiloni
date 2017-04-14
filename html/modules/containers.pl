%MSG = loadLang('Containers');

my $html;
$html .= qq~
<table cellpadding="0" cellspacing="0" width="100%"><tr>
<td width="50%">
<div class="contentTitle">$MSG{Containers_Management}</div>
</td>
<tr><td width="50%">

</td>
</tr></table>
~ unless $input{'shtl'};

if ( $input{submod} eq 'startContainer' ) {
	if ( $input{IDsContainers} ) {
		connected();
		$sth = $dbh->prepare("SELECT s.IPv4, s.privateKey, c.containerName, c.locked FROM containers c, lxcservers s WHERE c.idServer = s.idServer AND c.idContainer IN ($input{IDsContainers})");
		$sth->execute();
		my $containers = $sth->fetchall_arrayref;
		$sth->finish;
		$dbh->disconnect if ($dbh);
		
		my %SRV;
		for my $i ( 0 .. $#{$containers} ) {
			$SRV{"$containers->[$i][0]=$containers->[$i][1]=$containers->[$i][3]"} .= "$containers->[$i][2]=";
		}
		
		use LXC::LXCWrapper;
		foreach my $HostAndKey ( keys %SRV ) {
			my ($host, $privateKey, $locked) = split(/\=/, $HostAndKey);
			my @containers = split(/\=/, $SRV{$HostAndKey});
			
			if ( $locked ) {
				$html .= qq~<font color="#FF0000">$MSG{Container} "$containers[0]" $MSG{is_locked_I_cant_start_it}.</font><br /><br />~;
				my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
				$log->Log("START:Container:Names=$containers[0]:");
				next;
			}
			
			my $lxc = LXC::LXCWrapper->new($host, $VAR{keyPath} . '/' . $privateKey);
			my $response = $lxc->start(\@containers);
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("START:Container:Names=" . join(';', @containers));
			
			# $html .= qq~$host, $privateKey, $SRV{$HostAndKey}<br><br>~;
		}
		# $html .= qq~CONTAINERS LIST: $input{IDsContainers}<br><br>~;
	}
	# print "Location: launcher.cgi?mod=containers\n\n";
}

if ( $input{submod} eq 'stopContainer' ) {
	if ( $input{IDsContainers} ) {
		connected();
		$sth = $dbh->prepare("SELECT s.IPv4, s.privateKey, c.containerName FROM containers c, lxcservers s WHERE c.idServer = s.idServer AND c.idContainer IN ($input{IDsContainers})");
		$sth->execute();
		my $containers = $sth->fetchall_arrayref;
		$sth->finish;
		$dbh->disconnect if ($dbh);
		
		my %SRV;
		for my $i ( 0 .. $#{$containers} ) {
			$SRV{"$containers->[$i][0]=$containers->[$i][1]"} .= "$containers->[$i][2]=";
		}
		
		foreach my $HostAndKey ( keys %SRV ) {
			my ($host, $privateKey) = split(/\=/, $HostAndKey);
			my @containers = split(/\=/, $SRV{$HostAndKey});
			
			use LXC::LXCWrapper;
			my $lxc = LXC::LXCWrapper->new($host, $VAR{keyPath} . '/' . $privateKey);
			my $response = $lxc->stop(\@containers);
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("STOP:Container:Names=" . join(';', @containers));
		}
	}
	
	print "Location: index.cgi?mod=containers\n\n";
}

if ( $input{submod} eq 'freezeContainer' ) {
	if ( $input{IDsContainers} ) {
		connected();
		$sth = $dbh->prepare("SELECT s.IPv4, s.privateKey, c.containerName FROM containers c, lxcservers s WHERE c.idServer = s.idServer AND c.idContainer IN ($input{IDsContainers})");
		$sth->execute();
		my $containers = $sth->fetchall_arrayref;
		$sth->finish;
		$dbh->disconnect if ($dbh);
		
		my %SRV;
		for my $i ( 0 .. $#{$containers} ) {
			$SRV{"$containers->[$i][0]=$containers->[$i][1]"} .= "$containers->[$i][2]=";
		}
		
		foreach my $HostAndKey ( keys %SRV ) {
			my ($host, $privateKey) = split(/\=/, $HostAndKey);
			my @containers = split(/\=/, $SRV{$HostAndKey});
			
			use LXC::LXCWrapper;
			my $lxc = LXC::LXCWrapper->new($host, $VAR{keyPath} . '/' . $privateKey);
			my $response = $lxc->freeze(\@containers);
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("FREZZE:Container:Names=" . join(';', @containers));
		}
	}
	
	print "Location: index.cgi?mod=containers\n\n";
}

if ( $input{submod} eq 'unfreezeContainer' ) {
	if ( $input{IDsContainers} ) {
		connected();
		$sth = $dbh->prepare("SELECT s.IPv4, s.privateKey, c.containerName FROM containers c, lxcservers s WHERE c.idServer = s.idServer AND c.idContainer IN ($input{IDsContainers})");
		$sth->execute();
		my $containers = $sth->fetchall_arrayref;
		$sth->finish;
		$dbh->disconnect if ($dbh);
		
		my %SRV;
		for my $i ( 0 .. $#{$containers} ) {
			$SRV{"$containers->[$i][0]=$containers->[$i][1]"} .= "$containers->[$i][2]=";
		}
		
		foreach my $HostAndKey ( keys %SRV ) {
			my ($host, $privateKey) = split(/\=/, $HostAndKey);
			my @containers = split(/\=/, $SRV{$HostAndKey});
			
			use LXC::LXCWrapper;
			my $lxc = LXC::LXCWrapper->new($host, $VAR{keyPath} . '/' . $privateKey);
			my $response = $lxc->unfreeze(\@containers);
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("UNFREZZE:Container:Names=" . join(';', @containers));
		}
	}
	
	print "Location: index.cgi?mod=containers\n\n";
}

if ( $input{submod} eq 'destroyContainer' ) {
	if ( $input{IDsContainers} ) {
			##$html .= qq~Containers: $input{IDsContainers}<br>~;
		connected();
		$sth = $dbh->prepare("SELECT c.idContainer, s.IPv4, s.privateKey, c.containerName, c.vgName, c.lvName FROM containers c, lxcservers s WHERE c.idServer = s.idServer AND c.idContainer IN ($input{IDsContainers})");
		$sth->execute();
		my $containers = $sth->fetchall_arrayref;
		$sth->finish;
		
		use Data::Dumper;
		use LXC::LXCWrapper;
		use LVM::LVMWrapper;
		for my $i ( 0 .. $#{$containers} ) {
			my $lxc = LXC::LXCWrapper->new($containers->[$i][1], $VAR{keyPath} . '/' . $containers->[$i][2]);
			my $response = $lxc->ping($containers->[$i][3]);
			$response = 'STOPPED' unless $response;
			
			if ( $response ne 'STOPPED' ) {
				$html .= qq~<font color="#FF0000">:$response: Container "$containers->[$i][3]" must be stopped so it can be destroyed.</font><br /><br />~;
				next;
			}
			
			my $lvm = LVM::LVMWrapper->new($containers->[$i][1], $VAR{keyPath} . '/' . $containers->[$i][2]);
			$response = $lvm->lvremove($containers->[$i][4], $containers->[$i][5], $containers->[$i][3]);
			
			my @containers = ($containers->[$i][3]);
			$response = $lxc->destroy(\@containers, 'force'); # 'force'
			
			my $sth1 = $dbh->prepare("DELETE FROM containers WHERE idContainer = '$containers->[$i][0]'");
			$sth1->execute();
			$sth1->finish;
			
			my $sth2 = $dbh->prepare("UPDATE cpus SET idContainer=NULL WHERE idContainer = '$containers->[$i][0]'");
			$sth2->execute();
			$sth2->finish;
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("DESTROY:Container:Name=$containers->[$i][3]");
		}
		
		$dbh->disconnect if $dbh;
	}
	
	# print "Location: index.cgi?mod=containers\n\n";
}

if ( $input{submod} eq 'cook_sector' ) {
	set_cookie_Sector($input{idSector});
	print "Location: index.cgi?mod=containers\n\n";
}

if ( $input{submod} eq 'save_record' ) {
	connected();
	$sth = $dbh->prepare("SELECT s.IPv4, s.privateKey, c.containerName FROM containers c, lxcservers s WHERE c.idServer = s.idServer AND c.idContainer = '$input{idContainer}'");
	$sth->execute();
	my ($host, $privateKey, $containerName) = $sth->fetchrow_array;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	$input{memory} = $input{memory}.'M' unless $input{memory} =~ /[MG]$/;
	
	if ( $input{protocolEth0} eq 'dhcp' ) {
		$input{ipAddr} = '';
		$input{gateway} = '';
		$input{netmask} = '';
		$input{network} = '';
		$input{broadcast} = '';
	}
	
	use LXC::LXCWrapper;
	my $lxc = LXC::LXCWrapper->new($host, $VAR{keyPath} . '/' . $privateKey);
	my $response = $lxc->update({
		Name		=> $containerName,
		hostname	=> $input{hostname},
		memory		=> $input{memory},
		Distro		=> $input{Distro},
		startAuto	=> $input{startAuto},
		startDelay	=> $input{startDelay},
		iface		=> 'eth0',
		proto		=> $input{protocolEth0},
		ipAddr		=> $input{ipAddr},
		gateway		=> $input{gateway},
		netmask		=> $input{netmask},
		network		=> $input{network},
		broadcast	=> $input{broadcast},
	});
	
	my $swap ;
	$swap = ($input{memory} * 4) . 'M' if $input{memory} =~ /M$/;
	$swap = ($input{memory} * 4) . 'G' if $input{memory} =~ /G$/;
	
	connected();
	my $sth = $dbh->prepare("UPDATE containers SET 
	hostname='$input{hostname}',
	memory='$input{memory}',
	swap='$swap',
	bootProto='$input{protocolEth0}',
	ipAddr='$input{ipAddr}',
	netmask='$input{netmask}',
	gateway='$input{gateway}',
	broadcast='$input{broadcast}',
	network='$input{network}',
	startAuto='$input{startAuto}',
	startDelay='$input{startDelay}',
	shortDescription='$input{shortDescription}'
	WHERE idContainer='$input{idContainer}'");
	$sth->execute();
	$sth->finish;
	$dbh->disconnect if $dbh;
	
	my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("UPDATE:Container:idContainer=$input{idContainer};hostname=$input{hostname};memory=$input{memory};swap=$swap;bootProto=$input{protocolEth0};ipAddr=$input{ipAddr};netmask=$input{netmask};gateway=$input{gateway};broadcast=$input{broadcast};network=$input{network};startAuto=$input{startAuto};startDelay=$input{startDelay};shortDescription=$input{shortDescription}");
	
	print "Location: index.cgi?mod=containers&idContainer=$input{idContainer}\n\n";
}






################################################################################################################################################
################################################################################################################################################
################################################################################################################################################
################################################################################################################################################









connected();
$sth = $dbh->prepare("SELECT idSector, sectorName FROM sector");
$sth->execute();
my $sector = $sth->fetchall_arrayref;
$sth->finish;
$dbh->disconnect if ($dbh);

my $cookie_Sector = get_cookie_Sector();

my $sector_option;
for my $i ( 0..$#{$sector} ) {
	my $selected = $sector->[$i][0] eq $cookie_Sector ? 'selected' : '';
	$sector_option .= qq~<option value="$sector->[$i][0]" $selected>$sector->[$i][1]</option>\n~;
}

										# my (%ssh, %ls);
										# ##multiple connections are established in parallel:
										# for my $host (@hosts) {
											# $ssh{$host} = Net::OpenSSH->new($host, async => 1);
										# }
										# ##then to run some command in all the hosts (sequentially):
										# for my $host (@hosts) {
											# $ssh{$host}->system('ls /');
										# }

$sth = $dbh->prepare("SELECT c.*, s.hostName, s.IPv4, s.privateKey FROM containers c, lxcservers s WHERE c.idServer = s.idServer AND s.idSector = '$cookie_Sector' ORDER BY containerName");
$sth->execute();
my $containers = $sth->fetchall_arrayref;
$sth->finish;
$dbh->disconnect if ($dbh);

$html .= qq~
<script>
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


<div style="padding: 0 0 6px 10px">


<div id="myModalRedirectStart" class="confirm"><div class="confirm-content">
	$MSG{Alert}<hr class="confirm-header">
	$MSG{Containers_are_starting_now}.<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
</div></div>
<button class="btn" onClick="return openModalRedirect('myModalRedirectStart', 'index.cgi?mod=containers&submod=startContainer&IDsContainers='+w2ui.grid.getSelection(), '_top');"><font color="00BB00">$MSG{Start}</font></button>


<div id="myModalRedirectStop" class="confirm"><div class="confirm-content">
	$MSG{Alert}<hr class="confirm-header">
	$MSG{Containers_are_stoping_now}.<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
</div></div>
<div id="myModalConfirmStop" class="confirm"><div class="confirm-content">
	$MSG{Please_confirm}<hr class="confirm-header">
	$MSG{Are_you_sure_you_want_STOP_these_containers}?
	<span class="confirm-bottom">
	<button onClick="return openModalCloseAndRedirect('myModalRedirectStop', 'myModalConfirmStop', 'index.cgi?mod=containers&submod=stopContainer&IDsContainers='+w2ui.grid.getSelection(), '_top');" class="blueLightButton">$MSG{Yes}</button>
	<button onClick="return closeModal('myModalConfirmStop');" class="greyButton">$MSG{Cancel}</button>
	</span>
</div></div>
<button class="btn" onClick="return openModal('myModalConfirmStop');"><font color="BB0000">$MSG{Stop}</font></button>


<div id="myModalRedirectDestroy" class="confirm"><div class="confirm-content">
	$MSG{Alert}<hr class="confirm-header">
	$MSG{Containers_are_destroying_now}.<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
</div></div>
<div id="myModalConfirmDestroy" class="confirm"><div class="confirm-content">
	$MSG{Please_confirm}<hr class="confirm-header">
	<font color="#FF0000">$MSG{Are_you_sure_you_want_DESTROY_these_containers}?</font><br>$MSG{Operation_will_destroy_all_data_and_will_not_be_recoverable}.
	<span class="confirm-bottom">
	<button onClick="return openModalCloseAndRedirect('myModalRedirectDestroy', 'myModalConfirmDestroy', 'index.cgi?mod=containers&submod=destroyContainer&IDsContainers='+w2ui.grid.getSelection(), '_top');" class="blueLightButton">$MSG{Yes}</button>
	<button onClick="return closeModal('myModalConfirmDestroy');" class="greyButton">$MSG{Cancel}</button>
	</span>
</div></div>
<button class="btn" onClick="return openModal('myModalConfirmDestroy');"><font color="BB0000">$MSG{Destroy}</font></button>


<div id="myModalRedirectFreeze" class="confirm"><div class="confirm-content">
	$MSG{Alert}<hr class="confirm-header">
	$MSG{Containers_are_freezing_now}.<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
</div></div>
<div id="myModalConfirmFreeze" class="confirm"><div class="confirm-content">
	$MSG{Please_confirm}<hr class="confirm-header">
	$MSG{Are_you_sure_you_want_FREEZE_these_containers}?
	<span class="confirm-bottom">
	<button onClick="return openModalCloseAndRedirect('myModalRedirectFreeze', 'myModalConfirmFreeze', 'index.cgi?mod=containers&submod=freezeContainer&IDsContainers='+w2ui.grid.getSelection(), '_top');" class="blueLightButton">$MSG{Yes}</button>
	<button onClick="return closeModal('myModalConfirmFreeze');" class="greyButton">$MSG{Cancel}</button>
	</span>
</div></div>
<button class="btn" onClick="return openModal('myModalConfirmFreeze');"><font color="#0066BB">$MSG{Freeze}</font></button>


<div id="myModalRedirectUnfreeze" class="confirm"><div class="confirm-content">
	$MSG{Alert}<hr class="confirm-header">
	$MSG{Containers_are_unfreeze_now}.<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
</div></div>
<button class="btn" onClick="return openModalRedirect('myModalRedirectUnfreeze', 'index.cgi?mod=containers&submod=unfreezeContainer&IDsContainers='+w2ui.grid.getSelection(), '_top');"><font color="0066BB">$MSG{Unfreeze}</font></button>



<button class="btn" onclick="var html_link = 'index.cgi?mod=provisioning';window.open(html_link, '_top');"><font color="#00BB00">$MSG{Launch}</font></button>

<button class="btn" onclick="var html_link = 'index.cgi?mod=migration&originIdContainer='+w2ui.grid.getSelection();window.open(html_link, '_top');"><font color="#C78815">$MSG{Migrate}</font></button>



&nbsp; &nbsp;
<a href="index.cgi?mod=containers"><img src="../images/refresh-32x35.png" style="height: 24px; display: inline; vertical-align: bottom" /></a>

&nbsp; &nbsp; &nbsp; &nbsp; 

<form method="get" action="index.cgi" style="display: inline-block;">
<input type="hidden" name="mod" value="containers">
<input type="hidden" name="submod" value="cook_sector">
<select name="idSector" onChange="this.form.submit();">
<option value=""> - $MSG{Please_Select_Sector} - </option>
$sector_option
</select>
</form>
</div>
~;
##<button class="btn" onclick="var html_link = 'index.cgi?mod=clone&IdContainer='+w2ui.grid.getSelection();window.open(html_link, '_top');"><font color="#C78815">Clone</font></button>

$html .= qq~
<div id="grid" style="width: 100%; height: 400px;"></div>

<script>
\$(function () {
    \$('\#grid').w2grid({
        name: 'grid',
        header: '$MSG{List_of_Containers}',
        show: { 
            //header      : true,
            toolbar     : true,
            footer      : true,
            //lineNumbers : true,
            selectColumn: true,
            //expandColumn: true
        },
        multiSelect: true,
        columns: [
			{ field: 'containerName', caption: '$MSG{Container_Name}', size: '140px', sortable: true, searchable: true },
			{ field: 'hostName', caption: '$MSG{Hostname}', size: '110px', sortable: true, searchable: true },
			{ field: 'status', caption: '$MSG{Status}', size: '90px', sortable: true },
			{ field: 'key', caption: '$MSG{Key}', size: '140px', sortable: true },
			{ field: 'bootProto', caption: '$MSG{Boot_Proto}', size: '90px', sortable: true },
			{ field: 'ipAddr', caption: '$MSG{IP_Addr}', size: '120px', sortable: true, searchable: true },
			{ field: 'lxcServer', caption: '$MSG{LXC_Server}', size: '90px', sortable: true, searchable: true },
			{ field: 'distribution', caption: '$MSG{Distribution}', size: '100px', sortable: true },
			{ field: 'release', caption: '$MSG{Release}', size: '70px', sortable: true },
			{ field: 'architecture', caption: '$MSG{Architecture}', size: '100px', sortable: true },
			{ field: 'storageProvisionedMode', caption: '$MSG{Storage}', size: '70px', sortable: true, searchable: true },
			{ field: 'lvSize', caption: '$MSG{LV_Size}', size: '70px', sortable: true },
			{ field: 'memory', caption: '$MSG{Memory}', size: '70px', sortable: true, searchable: true },
			{ field: 'cpu', caption: '$MSG{CPU}', size: '60px', sortable: true },
			{ field: 'perCentCpu', caption: '$MSG{percent_Cpu}', size: '60px', sortable: true, searchable: true },
			{ field: 'creationDate', caption: '$MSG{Creation_Date}', size: '150px', sortable: true, searchable: true },
        ],
        records: [
        ~;
        
		use LXC::LXCWrapper;
		for my $i ( 0 .. $#{$containers} ) {
			# my $lxc = LXC::LXCWrapper->new($host, $VAR{keyPath} . '/' . $privateKey);
			my $lxc = LXC::LXCWrapper->new($containers->[$i][37], $VAR{keyPath} . '/' . $containers->[$i][38]);
			
			if ( $containers->[$i][16] eq 'dhcp' ) {
				my $response = $lxc->info([$containers->[$i][2]]);
				$containers->[$i][17] = $response->{$containers->[$i][2]}{IP};
			}
			
			my $status;
			my $lxcServer = $containers->[$i][36];
			
			if ( $lxc->{error} ) {
				$lxcServer = qq~<font color="#BB0000"><b>$lxcServer</b></font>~;
			} else {
				$status = $lxc->ping($containers->[$i][2]);
				$status = 'MISSING' unless $status;
				
				my $colorSatatus = '#FFA500';
				if ( $status eq 'RUNNING' ) {
					$colorSatatus = '#00BB00';
				} elsif ( $status eq 'STOPPED' ) {
					$colorSatatus = '#BB0000';
				} elsif ( $status eq 'FROZEN' ) {
					$colorSatatus = '#0077BB';
				}
				
				if ( $containers->[$i][35] eq '1' ) {
					$status = 'LOCKED';
					$colorSatatus = '#880000';
				}
				$status = qq~<font color="$colorSatatus">$status</font>~;
			}
			$containers->[$i][16] = uc($containers->[$i][16]);
			$html .= qq~{
			recid: '$containers->[$i][0]',
			containerName: '$containers->[$i][2]',
			hostName: '$containers->[$i][3]',
			status: '$status',
			key: '$containers->[$i][28]',
			bootProto: '$containers->[$i][16]',
			ipAddr: '$containers->[$i][17]',
			lxcServer: '$lxcServer',
			distribution: '$containers->[$i][5]',
			release: '$containers->[$i][6]',
			architecture: '$containers->[$i][7]',
			storageProvisionedMode: '$containers->[$i][10]',
			lvSize: '$containers->[$i][13]',
			memory: '$containers->[$i][24]',
			cpu: '$containers->[$i][26]',
			perCentCpu: '$containers->[$i][27]',
			creationDate: '$containers->[$i][32]',
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
                    var html_link = 'launcher.cgi?mod=containers_edit&idContainer='+recid;
                    window.open(html_link, 'edition_frame');
                } else {
                    var html_link = 'launcher.cgi?mod=containers_edit';
                    window.open(html_link, 'edition_frame');
                    form.clear();
                }
            }
        }
    });
});
</script>

<iframe name="edition_frame" src="launcher.cgi?mod=containers_edit&idContainer=$input{idContainer}" class="edition_frame" onload="this.style.height=this.contentDocument.body.scrollHeight +'px';"></iframe>

<br />
<br />
~;


return $html;
1;
