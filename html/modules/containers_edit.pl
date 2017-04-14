%MSG = loadLang('containers_edit');

my $html;

if ( $input{idContainer} ) {
	connected();
	my $sth = $dbh->prepare("SELECT * FROM containers WHERE idContainer = '$input{idContainer}'");
	$sth->execute();
	my @data = $sth->fetchrow_array;
	$sth->finish;
	
	# $sth = $dbh->prepare("SELECT distroData, showData FROM distros WHERE active = '1'");
	# $sth->execute();
	# my $distro = $sth->fetchall_arrayref;
	# $sth->finish;
	
	$sth = $dbh->prepare("SELECT s.memory-SUM(c.memory) FROM containers c, lxcservers s WHERE c.idServer = s.idServer AND c.idServer = '$data[1]'");
	$sth->execute();
	my ($freeMem) = $sth->fetchrow_array;
	$sth->finish;
	
	$dbh->disconnect if ($dbh);
	
	my $bootProtoSelect;
	my $selected = $data[16] eq 'static' ? 'selected' : '';
	$bootProtoSelect .= qq~<option value="static" $selected>Static</option>~;
	$selected = $data[16] eq 'dhcp' ? 'selected' : '';
	$bootProtoSelect .= qq~<option value="dhcp" $selected>DHCP</option>~;
	$selected = undef;
	
	my $startAutoSelect;
	$selected = $data[29] eq '1' ? 'selected' : '';
	$startAutoSelect .= qq~<option value="1" $selected>$MSG{Yes}</option>~;
	$selected = $data[29] eq '0' ? 'selected' : '';
	$startAutoSelect .= qq~<option value="0" $selected>$MSG{No}</option>~;
	$selected = undef;
	
	# my $onlyDataBaseChecked = '0';
	# $onlyDataBaseChecked = $input{onlyDataBase} eq '1' ? 'checked' : '';
	# my $opositeOnlyDataBase;
	# $opositeOnlyDataBase = $input{onlyDataBase} eq '1' ? '0' : '1';
			# <tr><td align="right" width="30%"> &nbsp; </td><td width="70%" style="padding: 8px 0 8px 2px; color: #008800; text-align: right">
			# Make changes only in Database <input type="checkbox" $onlyDataBaseChecked onChange="return window.open('launcher.cgi?mod=containers_edit&onlyDataBase=$opositeOnlyDataBase&idContainer=$data[0]', 'edition_frame')">
			# </td></tr>
	
	# unless ( $input{onlyDataBase} ) {
		my $totalMaxMem = $data[24] + $freeMem;
		$html .= qq~
			<div id="miquiloniToolTip"></div>
			<script>
				function openModal(modalId) {
					document.getElementById(modalId).style.display = "block";
				}
				function closeModal(modalId) {
					document.getElementById(modalId).style.display = "none";
				}
				function openModalCloseAndRedirect(modalIdToOpen, modalIdToClose, htmlink, targetLink) {
					document.getElementById(modalIdToClose).style.display = "none";
					document.getElementById(modalIdToOpen).style.display = "block";
				}
			</script>
			
			<form method="get" action="index.cgi" target="_top">
			<input type="hidden" name="mod" value="containers">
			<input type="hidden" name="submod" value="save_record">
			<input type="hidden" name="idContainer" value="$data[0]">
			<input type="hidden" name="Distro" value="$data[5]">
			
			<table cellpadding="0" cellspacing="0" class="formTitle">
			<tr><td style="font-size: 12px">$MSG{Editing_Container} <b>$data[2]</b></td></tr>
			</table>
			
			<table cellpadding="0" cellspacing="0" class="form">
			
			
			
			<tr><td align="right" width="30%">$MSG{Hostname}: </td><td width="70%"><input type="text" name="hostname" value="$data[3]" maxlength="16"> &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; 
			<img src="../images/help-32x32.png" width="20" onMouseOver="showToolTip('$MSG{You_must_restart_this_container_for_the_changes_take_effect}', '', '', '');" onMouseout="hideToolTip();" />
			</td></tr>
			
			<tr><td align="right" width="30%">$MSG{Distro}: </td><td width="70%" style="padding: 8px 0 8px 2px; color: #008800"> $data[5] $data[6] $data[7]</td></tr>
			<tr><td align="right" width="30%">$MSG{Root_Volume_Size}: </td><td width="70%" style="padding: 8px 0 8px 2px; color: #008800"> $data[13]</td></tr>
			
			<tr><td align="right" width="30%">$MSG{Boot_proto}: </td><td width="70%">
			<select name="protocolEth0">$bootProtoSelect</select>
			</td></tr>
			
			<tr><td align="right" width="30%">IPv4: </td><td width="70%"><input type="text" name="ipAddr" value="$data[17]"></td></tr>
			<tr><td align="right" width="30%">$MSG{Netmask}: </td><td width="70%"><input type="text" name="netmask" value="$data[18]"></td></tr>
			<tr><td align="right" width="30%">$MSG{Gateway}: </td><td width="70%"><input type="text" name="gateway" value="$data[19]"></td></tr>
			<tr><td align="right" width="30%">$MSG{Broadcast}: </td><td width="70%"><input type="text" name="broadcast" value="$data[20]"></td></tr>
			<tr><td align="right" width="30%">$MSG{Network}: </td><td width="70%"><input type="text" name="network" value="$data[21]"></td></tr>
			
			<tr><td align="right" width="30%">$MSG{Memory} (<font color="#FF0000">$freeMem MiB $MSG{free}</font>): </td><td width="70%"><input type="text" name="memory" value="$data[24]"> 
			<img src="../images/help-32x32.png" width="16" onMouseOver="showToolTip('$MSG{Dont_exceed_the_limit_of} $freeMem MiB $MSG{plus_the_current_value_of_this_Container} ($totalMaxMem MiB).', '', '', '');" onMouseout="hideToolTip();" />
			</td></tr>
			
			<tr><td align="right" width="30%">$MSG{CPUs_ID}: </td><td width="70%" style="padding: 8px 0 8px 2px; color: #008800">$data[26]</td></tr>
			<tr><td align="right" width="30%">$MSG{CPU_Percent}: </td><td width="70%" style="padding: 8px 0 8px 2px; color: #008800">$data[27]</td></tr>
			
			<tr><td align="right" width="30%">$MSG{Start_Auto}: </td><td width="70%">
			<select name="startAuto">$startAutoSelect</select>
			</td></tr>
			
			<tr><td align="right" width="30%">$MSG{Start_Delay}: </td><td width="70%"><input type="text" name="startDelay" value="$data[30]" style="width: 20px"></td></tr>
			<tr><td align="right" width="30%">$MSG{Short_Description}: </td><td width="70%"><input type="text" name="shortDescription" value="$data[31]" style="width:400px"></td></tr>
			<tr><td align="right" width="30%">$MSG{Creation_Date}: </td><td width="70%" style="padding: 8px 0 8px 2px; color: #008800">$data[32]</td></tr>
			
			</table>
			
			<table cellpadding="0" cellspacing="0" class="formFooter">
			<tr><td>
			
			<div id="myModalRedirectStop" class="confirm"><div class="confirm-content">
				$MSG{Alert}<hr class="confirm-header">
				$MSG{Container_is_updating_now}.<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
			</div></div>
			<div id="myModalConfirmStop" class="confirm"><div class="confirm-content">
				$MSG{Please_confirm}<hr class="confirm-header">
				$MSG{Are_you_sure_you_want_UPDATE_this_container}?
				<span class="confirm-bottom">
				<button href="#" onClick="return openModalCloseAndRedirect('myModalRedirectStop', 'myModalConfirmStop', '', '_top');" class="blueLightButton">$MSG{Yes}</button>
				<a onClick="return closeModal('myModalConfirmStop');" class="greyButton">$MSG{Cancel}</a>
				</span>
			</div></div>
			<a class="blueLightButton" onClick="return openModal('myModalConfirmStop');">$MSG{Save}</a>
			
			
			
			<input type="reset" value="$MSG{Reset}" class="greyButton">
			</td></tr>
			</table>
			
			</form>
			
			<br><br>
		~;
	# } else {<button value="Save" class="blueLightButton">Save</button> 
		
		
		# my $optionDistro;
		# for my $i ( 0 .. $#{$distro} ) {
			# my $selected = $distro->[$i][1] =~ /$data[5].$data[6].$data[7]/i ? 'selected' : '';
			# $optionDistro .= qq~<option value="$distro->[$i][0]" $selected>$distro->[$i][1]</option>\n~;
		# }
			
		# $html .= qq~
			
			# <form method="get" action="launcher.cgi" target="_top">
			# <input type="hidden" name="mod" value="containers">
			# <input type="hidden" name="submod" value="save_record">
			# <input type="hidden" name="idContainer" value="$data[0]">
			# <input type="hidden" name="onlyDataBase" value="1">
			
			# <table cellpadding="0" cellspacing="0" class="formTitle">
			# <tr><td style="font-size: 12px">Editing <b>$data[2]</b></td></tr>
			# </table>
			
			# <table cellpadding="0" cellspacing="0" class="form">
			
			# <tr><td align="right" width="30%"> &nbsp; </td><td width="70%" style="padding: 8px 0 8px 2px; color: #008800; text-align: right">
			# Make changes only in Database <input type="checkbox" $onlyDataBaseChecked onChange="return window.open('launcher.cgi?mod=containers_edit&onlyDataBase=$opositeOnlyDataBase&idContainer=$data[0]', 'edition_frame')">
			# </td></tr>
			
			# <tr><td align="right" width="30%"> &nbsp; </td><td width="70%" style="padding: 8px 0 12px 2px; color: #880000">
			# In Database only.<br>
			# Changes made with this option, never will make in container.<br>
			# Use this option just to update a record for container manually modified.
			# </td></tr>
			
			# <tr><td align="right" width="30%">Host Name: </td><td width="70%"><input type="text" name="hostName" value="$data[3]" maxlength="16"></td></tr>
			
			# <tr><td align="right" width="30%">Distro: </td><td width="70%" style="padding: 8px 0 8px 2px; color: #008800">
			# <select name="distro" style="width: 200px;">
			# $optionDistro
			# </select>
			# </td></tr>
			
			# <tr><td align="right" width="30%">Root Volume Size: </td><td width="70%" style="padding: 8px 0 8px 2px; color: #008800">$data[13]</td></tr>
			
			# <tr><td align="right" width="30%">Boot proto: </td><td width="70%">
			# <select name="bootProto">$bootProtoSelect</select>
			# </td></tr>
			
			# <tr><td align="right" width="30%">IPv4: </td><td width="70%"><input type="text" name="IPv4" value="$data[16]"></td></tr>
			# <tr><td align="right" width="30%">Netmask: </td><td width="70%"><input type="text" name="netmask" value="$data[17]"></td></tr>
			# <tr><td align="right" width="30%">Gateway: </td><td width="70%"><input type="text" name="gateway" value="$data[18]"></td></tr>
			# <tr><td align="right" width="30%">Broadcast: </td><td width="70%"><input type="text" name="broadcast" value="$data[19]"></td></tr>
			# <tr><td align="right" width="30%">Network: </td><td width="70%"><input type="text" name="network" value="$data[20]"></td></tr>
			# <tr><td align="right" width="30%">Memory: </td><td width="70%"><input type="text" name="memory" value="$data[23]"></td></tr>
			# <tr><td align="right" width="30%">CPU's ID: </td><td width="70%"><input type="text" name="memory" value="$data[25]" style="width: 30px"></td></tr>
			# <tr><td align="right" width="30%">CPU Percent: </td><td width="70%"><input type="text" name="memory" value="$data[26]" style="width: 30px"></td></tr>
			
			# <tr><td align="right" width="30%">Start Auto: </td><td width="70%">
			# <select name="startAuto">$startAutoSelect</select>
			# </td></tr>
			
			# <tr><td align="right" width="30%">Start Delay: </td><td width="70%"><input type="text" name="startDelay" value="$data[28]" style="width: 20px"></td></tr>
			# <tr><td align="right" width="30%">Short Description: </td><td width="70%"><input type="text" name="shortDescription" value="$data[29]" style="width:400px"></td></tr>
			# <tr><td align="right" width="30%">Creation Date: </td><td width="70%" style="padding: 8px 0 8px 2px; color: #008800">$data[30]</td></tr>
			
			# </table>
			
			# <table cellpadding="0" cellspacing="0" class="formFooter">
			# <tr><td>
			# <button value="Save" class="blueLightButton">Save</button>
			# <input type="reset" value="Reset" class="greyButton">
			# </td></tr>
			# </table>
			
			# </form>
			
			# <br><br>
		# ~;
	# }
}
else {
	$html .= qq~
	No Container selected
	~;
}



# 0	idContainer
# 1	idServer
# 2	containerName
# 3	hostName
# 4	template_
# 5	distribution
# 6	release_
# 7	architecture
# 8	variant
# 9	noValidate
# 10	storageProvisionedMode
# 11	vgName
# 12	lvName
# 13	lvSize
# 14	fstype
# 15	memory
# 16	cpu
# 17	perCentCpu
# 18	swap
# 19	bootProto
# 20	ipAddr
# 21	netmask
# 22	gateway
# 23	broadcast
# 24	network
# 25	dns1
# 26	dns2
# 27	shortDescription
# 28	creationDate









return $html;
1;
