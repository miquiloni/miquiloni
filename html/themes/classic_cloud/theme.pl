sub header {
	my $header;
	
	unless ( $shtl ) {
		$header .= qq~
		<--//<link href="../css/stylelauncher.css" rel="stylesheet" type="text/css" />//-->
		
		<link rel="stylesheet" type="text/css" href="../css/w2ui-1.4.3.min.css" />
		<script src="../js/jquery/2.1.1/jquery.min.js"></script>
		<script type="text/javascript" src="../js/w2ui-1.4.3.min.js"></script>
		
		<script type="text/javascript" src="../js/miquiloniToolTip.js"></script>
		
	</head>
<body>
	~; #http://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js
	} else {
		$header .= qq~
	</head>
<body>
	~;
	}
	
	my ($ahome, $aoverview, $aprovisioning, $asectors, $alxcservers, $acontainers, $akeypairs, $aaccounts, $asettings, $adistros, $aabout, $adocs, $ahelp, $alegal, $atabs);
	unless ( $input{mod} ) { $ahome = 'active' }
	if ( $input{mod} eq 'overview' ) { $aoverview = 'active' }
	if ( $input{mod} eq 'provisioning' ) { $aprovisioning = 'active' }
	if ( $input{mod} eq 'sectors' ) { $asectors = 'active' }
	elsif ( $input{mod} eq 'lxcservers' ) { $alxcservers = 'active' }
	elsif ( $input{mod} eq 'containers' ) { $acontainers = 'active' }
	elsif ( $input{mod} eq 'keypairs' ) { $akeypairs = 'active' }
	elsif ( $input{mod} eq 'accounts' ) { $aaccounts = 'active' }
	elsif ( $input{mod} eq 'settings' ) { $asettings = 'active' }
	elsif ( $input{mod} eq 'distros' ) { $adistros = 'active' }
	elsif ( $input{mod} eq 'docs' and $input{tab} eq '2' ) { $aabout = 'active' }
	elsif ( $input{mod} eq 'docs' and $input{tab} eq '0' ) { $adocs = 'active' }
	elsif ( $input{mod} eq 'docs' and $input{tab} eq '1' ) { $ahelp = 'active' }
	elsif ( $input{mod} eq 'docs' and $input{tab} eq '3' ) { $alegal = 'active' }
	
	if ( $username ne 'Guest' ) {
		$header .= qq~
		<ul class="topnavbar">
			<li class="topnavbar" style="margin-left: 40px"><img src="themes/$theme/images/red-home.png" style="height: 18px; padding-top: 8px" align="left"><a href="index.cgi" class="$aoverview">$MSG{Home}</a></li>
			<li class="topnavbar"><img src="themes/$theme/images/vserver.png" style="height: 18px; padding-top: 9px" align="left"><a href="index.cgi?mod=provisioning" class="$aprovisioning">$MSG{Provisioning}</a></li>
			<li class="topnavbar"><img src="themes/$theme/images/user.png" style="height: 18px; padding-top: 9px" align="left"><a href="index.cgi?mod=settings" class="$asettings">$MSG{My_Account} [$username]</a></li>
			<li class="topnavbar"><img src="themes/$theme/images/help-yellow-32x32.png" style="height: 18px; padding-top: 9px" align="left"><a href="index.cgi?mod=docs&tab=2" class="$aabout">$MSG{About}</a></li>
			<li class="topnavbar" style="float:right"><a href="index.cgi?mod=logout" onclick="return confirm('$MSG{Are_you_sure_you_want_to_log_off} ?')">$MSG{Log_off}</a></li>
		</ul>
		
		<ul class="leftnavbar">
			<li class="leftnavbar"><a href="index.cgi?mod=overview" class="$aoverview">$MSG{Overview}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=lxcservers" class="$alxcservers">$MSG{LXC_Servers}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=containers" class="$acontainers">$MSG{Containers}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=keypairs" class="$akeypairs">$MSG{Key_Pairs}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=provisioning" class="$aprovisioning">$MSG{Provisioning}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=sectors" class="$asectors">$MSG{Sectors}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=accounts" class="$aaccounts">$MSG{Accounts}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=distros" class="$adistros">$MSG{Distros}</a></li>
			<hr style="border: 0;  height: 1px; background: linear-gradient(to right, rgba(0, 0, 0, 0), rgba(0, 0, 0, 0.25), rgba(0, 0, 0, 0)); align: center; margin: 12px 5px" noshadow />
			<!--<li class="leftnavbar"><a href="#Cloning" class="">Cloning</a></li>-->
			<!--<li class="leftnavbar"><a href="#Devices" class="">Devices</a></li>-->
			<!--<li class="leftnavbar"><a href="#backup" class="">Backup Policies</a></li>-->
			<!--<li class="leftnavbar"><a href="#backupschedule" class="">Backup Schedules</a></li>-->
			<!--<li class="leftnavbar"><a href="#recovery" class="">Recovery</a></li>-->
			<li class="leftnavbar"><a href="index.cgi?mod=docs&tab=0" class="$adocs">$MSG{Documentation}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=docs&tab=1" class="$ahelp">$MSG{Help}</a></li>
			<li class="leftnavbar"><a href="index.cgi?mod=docs&tab=3" class="$alegal">$MSG{Legal_License}</a></li>
		</ul>
		
		<div class="content">
		~;
	}
	
	return $header;
}

sub footer {
	my $footer;
	
	if ( $username ne 'Guest' ) {
		$footer .= qq~
		</div>
</body>
</html>
~;
	}
	return $footer;
}

1;
