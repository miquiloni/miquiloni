%MSG = loadLang('lxcservers_edit');

my $html;

connected();
my $sth = $dbh->prepare("SELECT * FROM sector");
$sth->execute();
my $sector = $sth->fetchall_arrayref;
$sth->finish;
$dbh->disconnect if ($dbh);

if ( $input{idServer} ) {
	connected();
	my $sth = $dbh->prepare("SELECT * FROM lxcservers WHERE idServer = '$input{idServer}'");
	$sth->execute();
	my @data = $sth->fetchrow_array;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	my $createContainersModeSelect;
	my $selected = $data[10] eq 'All' ? 'selected' : '';
	$createContainersModeSelect .= qq~<option value="All" $selected>$MSG{All_complete_and_partial_cores}</option>~;
	# $selected = $data[10] eq 'Complete_Cores' ? 'selected' : '';
	# $createContainersModeSelect .= qq~<option value="Complete_Cores" $selected>Complete Cores</option>~;
	# $selected = $data[10] eq 'Shared_Cores' ? 'selected' : '';
	# $createContainersModeSelect .= qq~<option value="Shared_Cores" $selected>Shared Cores</option>~;
	$selected = undef;
	
	my $storageProvisioningModeSelect;
	$selected = $data[11] eq 'LVM' ? 'selected' : '';
	$storageProvisioningModeSelect .= qq~<option value="LVM" $selected>LVM</option>~;
	# $selected = $data[11] eq 'Local' ? 'selected' : '';
	# $storageProvisioningModeSelect .= qq~<option value="Local" $selected>Local</option>~;
	$selected = undef;
	
	my $sectorSelect;
	for my $i ( 0 .. $#{$sector} ) {
		if ( $sector->[$i][0] eq $data[13] ) {
			$selected = 'selected';
		} else {
			$selected = '';
		}
		$sectorSelect .= qq~<option value="$sector->[$i][0]" $selected>$sector->[$i][1] ($sector->[$i][2])</option>~;
	}
	$selected = undef;
	
	my @lsKeys = split(/\n/, `ls $VAR{keyPath} | sed 's/\.pub//' | sort -u`);
	my $selectKeyPair = qq~<select name="privateKey" style="width: 200px;">~;
	for my $key ( @lsKeys ) {
		my $keyName = $key;
		$keyName =~ s/\.key$//;
		if ( $key eq $data[9] ) {
			$selected = 'selected';
		} else {
			$selected = '';
		}
		$selectKeyPair .= qq~<option value="$key" $selected>$keyName</option>\n~ ;
	}
	$selectKeyPair .= qq~</select>~;
	
	$html .= qq~
		<script>
			function openModal(modalId) {
				document.getElementById(modalId).style.display = "block";
			}
			function closeModal(modalId) {
				document.getElementById(modalId).style.display = "none";
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
		<div id="miquiloniToolTip"></div>
		<form method="get" action="index.cgi" target="_parent">
		<input type="hidden" name="mod" value="lxcservers">
		<input type="hidden" name="submod" value="save_record">
		<input type="hidden" name="idServer" value="$data[0]">
		
		<table cellpadding="0" cellspacing="0" class="formTitle">
		<tr><td style="font-size: 12px">$MSG{Editing} <b>$data[1]</b></td></tr>
		</table>
		
		<table cellpadding="0" cellspacing="0" class="form">
		
		<tr><td align="right" width="30%">$MSG{HostName}: </td><td width="70%"><input type="text" name="hostName" value="$data[1]" maxlength="16"></td></tr>
		<tr><td align="right" width="30%">IPv4: </td><td width="70%"><input type="text" name="IPv4" value="$data[2]"></td></tr>
		
		<tr><td align="right" width="30%">$MSG{Memory}: </td><td width="70%"><input type="text" name="memory" value="$data[4]">
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{Memory_value_in_MBytes}', '', '', '');" onMouseout="hideToolTip();" />
		</td></tr>
		
		<tr><td align="right" width="30%">CPUs: </td><td width="70%" style="padding: 8px 0 8px 0"> &nbsp; <b>$data[5]</b></td></tr>
		<tr><td align="right" width="30%">$MSG{CPU_Make}: </td><td width="70%"><input type="text" name="cpuMake" value="$data[6]"></td></tr>
		<tr><td align="right" width="30%">$MSG{CPU_Model}: </td><td width="70%"><input type="text" name="cpuModel" value="$data[7]"></td></tr>
		<tr><td align="right" width="30%">$MSG{CPU_Speed}: </td><td width="70%"><input type="text" name="cpuSpeed" value="$data[8]"></td></tr>
		<tr><td align="right" width="30%">$MSG{Private_Key}: </td><td width="70%">$selectKeyPair</td></tr>
		
		<tr><td align="right" width="30%" style="color: #FFA500">$MSG{Password_for_LXC_Server}: </td><td width="70%"><input type="password" name="passwd4LXCserver">
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{Password_wont_storage_only_will_use_it_if_you_wish_update_Private_Key_in}', '', '', '');" onMouseout="hideToolTip();" />
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Create_Containers_Mode}: </td><td width="70%">
		<select name="createContainersMode">
		$createContainersModeSelect
		</select>
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Storage_Provisioning_Mode}: </td><td width="70%">
		<select name="storageProvisioningMode">
		$storageProvisioningModeSelect
		</select>
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Short_Description}: </td><td width="70%"><input type="text" name="shortDescription" style="width:400px" value="$data[12]"></td></tr>
		
		<tr><td align="right" width="30%">Sector: </td><td width="70%">
		<select name="sectorId">
		$sectorSelect
		</select>
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Creation_Date}: </td><td width="70%" style="padding: 10px 20px;">$data[14]</td></tr>
		
		</table>
		
		<table cellpadding="0" cellspacing="0" class="formFooter"><tr><td>
		
		<div id="myModalRedirectSave" class="confirm"><div class="confirm-content">
			Alert<hr class="confirm-header">
			Saving changes for container $data[1].<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
		</div></div>
		<button class="blueLightButton" onClick="return openModal('myModalRedirectSave');">$MSG{Save}</button>
		
		</form>
		
		&nbsp;&nbsp;&nbsp;
		
		<a class="redButton" href="index.cgi?mod=lxcservers&submod=delete_record&idServer=$data[0]" target="_top" onclick="return confirm('$MSG{Are_you_sure_you_want_to_continue_deleting_the} $data[1] Server?')">$MSG{Delete}</a>
		
		</td></tr>
		</table>
		
		<br>
		
		
	~;
} else {
	
	my $createContainersModeSelect .= qq~<option value="All">$MSG{All_complete_and_partial_cores}</option>~;
	# $createContainersModeSelect .= '<option value="Complete_Cores">Complete Cores</option>';
	# $createContainersModeSelect .= '<option value="Shared_Cores">Shared Cores</option>';
	
	my $storageProvisioningModeSelect .= '<option value="LVM">LVM</option>';
	# $storageProvisioningModeSelect .= '<option value="Local">Local</option>';
	
	my $sectorSelect;
	for my $i ( 0 .. $#{$sector} ) {
		$sectorSelect .= qq~<option value="$sector->[$i][0]">$sector->[$i][1] ($sector->[$i][2])</option>~;
	}
	
	my @lsKeys = split(/\n/, `ls $VAR{keyPath} | sed 's/\.pub//' | sort -u`);
	my $selectKeyPair = qq~<select name="privateKey" style="width: 200px;">~;
	for my $key ( @lsKeys ) {
		my $keyName = $key;
		$keyName =~ s/\.key$//;
		$selectKeyPair .= qq~<option value="$key">$keyName</option>\n~ ;
	}
	$selectKeyPair .= qq~</select>~;
	
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
		<div id="miquiloniToolTip"></div>
		
		<form method="get" action="index.cgi" target="_parent">
		<input type="hidden" name="mod" value="lxcservers">
		<input type="hidden" name="submod" value="new_record">
		
		<table cellpadding="0" cellspacing="0" class="formTitle">
		<tr><td style="font-size: 12px">$MSG{Register_new_Server}</b></td></tr>
		</table>
		
		<table cellpadding="0" cellspacing="0" class="form">
		
		<tr><td align="right" width="30%">$MSG{HostName}: </td><td width="70%"><input type="text" name="hostName" maxlength="16"></td></tr>
		<tr><td align="right" width="30%">IPv4: </td><td width="70%"><input type="text" name="IPv4"></td></tr>
		
		<tr><td align="right" width="30%">$MSG{Memory_in_MiB}: </td><td width="70%"><input type="text" name="memory">
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{Memory_value_in_MBytes}', '', '', '');" onMouseout="hideToolTip();" />
		</td></tr>
		
		<tr><td align="right" width="30%">CPUs: </td><td width="70%"><input type="text" name="cpus">
		<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{CPU_will_be_an_unmodifiable_value_after_you_save}.<br />$MSG{You_should_be_sure_of_this_value}', '', '', '');" onMouseout="hideToolTip();" />
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{CPU_Make}: </td><td width="70%"><input type="text" name="cpuMake"></td></tr>
		<tr><td align="right" width="30%">$MSG{CPU_Model}: </td><td width="70%"><input type="text" name="cpuModel"></td></tr>
		<tr><td align="right" width="30%">$MSG{CPU_Speed}: </td><td width="70%"><input type="text" name="cpuSpeed"></td></tr>
		
		<tr><td align="right" width="30%">$MSG{Private_Key}: </td><td width="70%">$selectKeyPair</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Create_Containers_Mode}: </td><td width="70%">
		<select name="createContainersMode">
		$createContainersModeSelect
		</select>
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Storage_Provisioning_Mode}: </td><td width="70%">
		<select name="storageProvisioningMode">
		$storageProvisioningModeSelect
		</select>
		</td></tr>
		
		<tr><td align="right" width="30%">$MSG{Short_Description}: </td><td width="70%"><input type="text" style="width:400px" name="shortDescription" maxlength="60"></td></tr>
		
		<tr><td align="right" width="30%">Sector: </td><td width="70%">
		<select name="sectorId">
		$sectorSelect
		</select>
		</td></tr>
		
		<tr><td align="right" width="30%">&nbsp;</td><td width="70%" align="right">
		<a href="index.cgi?mod=sectors" title="$MSG{Edit_Sectors}" target="_top"><img src="../images/location32x32.png" /></a>
		</td></tr>
		
		</table>
		
		<table cellpadding="0" cellspacing="0" class="formFooter">
		<tr><td>
		<div id="myModalRedirectSave" class="confirm"><div class="confirm-content">
			Alert<hr class="confirm-header">
			$MSG{Adding_new_LXC_Server}.<br /><br />$MSG{Please_wait_a_while_and_dont_close_this_window}
		</div></div>
		<button class="blueLightButton" onClick="return openModal('myModalRedirectSave');">$MSG{Save}</button>
		
		</form>
		</td></tr>
		</table>
		
		<br><br>
	~;
}

return $html;
1;
