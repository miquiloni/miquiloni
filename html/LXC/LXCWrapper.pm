########################################################################
# Miquiloni is a Web UI for LXC Servers management
# Copyright (C) 2017  Hugo Maza M.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
########################################################################
package LXC::LXCWrapper;

our $VERSION = '0.1';

use strict;
use Net::OpenSSH;

sub new {
	my $class = shift;
	my ($remoteHost, $private_key_path, $user, $timeout, $password) = @_;
	my $self = {};
	
	bless( $self, $class );
	
	my $ssh;
	if ( $private_key_path ) {
		$ssh = Net::OpenSSH->new(
			$remoteHost,
			key_path	=> $private_key_path,
			user		=> $user || 'root',
			timeout		=> $timeout || 6,
			master_opts	=> [-o => "StrictHostKeyChecking=no"],
		);
	} elsif ( $password ) {
		$ssh = Net::OpenSSH->new(
			$remoteHost,
			user		=> $user || 'root',
			timeout		=> $timeout || 6,
			master_opts	=> [-o => "StrictHostKeyChecking=no"],
			password	=> $password,
		);
	}
    
	$self->{server} = $ssh;
	$self->{error} = $ssh->error if $ssh->error;
	
	return $self;
}

sub ping {
	my $self = shift;
	my $container = shift;
	
	my $status = $self->{server}->capture("lxc-ls -f | grep -w $container | awk '{print \$2}'");
	chomp $status;
	$| = 1;
	return $status;
}

sub info {
	my $self = shift;
	my $containers = shift;
	my %INFO;
	
	if ( $containers->[0] eq 'all' ) {
		@$containers = split(/\n/, $self->{server}->capture("lxc-ls -f | awk '{print \$1}' | grep -v NAME"));
	}
	
	for my $container (@$containers) {
		%INFO = ($self->addConf($container), %INFO);
		
		my @resp = $self->{server}->capture("lxc-info -n $container");
		
		foreach my $line ( @resp ) {
			chomp($line);
			my ($key, $value) = split(/\:/, $line);
			$key =~ s/^\s+//;
			$value =~ s/^\s+//;
			# $self->{server}{$container}{$key} = $value;
			$INFO{$container}{$key} = $value;
		}
	}
	
	# $self->{server} = \%INFO;
	# return $self->{server};
	return \%INFO;
}

sub addConf {
	my $self = shift;
	my $container = shift;
	my %INFO;
	
	my $lxcPath = $self->{server}->capture("lxc-config lxc.lxcpath");
	chomp $lxcPath;
	my @containerConfig = $self->{server}->capture("cat $lxcPath/$container/config");
	chomp(@containerConfig);
	foreach my $conf ( @containerConfig ) {
		chomp $conf;
		$conf =~ s/^lxc\.//;
		if ( $conf and $conf !~ /^#/ ) {
			my ($ky, $vl) = split(/ = /, $conf);
			$INFO{$container}{$ky} = $vl if $ky =~ /rootfs|arch|network\.link|arch|cgroup|start|limits\.cpu/;
		}
	}
	return %INFO;
}

sub stop {
	my $self = shift;
	my $containers = shift;
	my %INFO;
	
	if ( $containers->[0] eq 'all' ) {
		@$containers = split(/\n/, $self->{server}->capture("lxc-ls -f | awk '{print \$1}' | grep -v NAME"));
	}
	
	for my $container (@$containers) {
		my @resp = $self->{server}->capture2({timeout => 1}, "lxc-stop -n $container");
		map {chomp $_; $INFO{$container} = $_;} @resp;
	}
	
	# $self->{server} = \%INFO;
	# return $self->{server};
	return \%INFO;
}

sub start {
	my $self = shift;
	my $containers = shift;
	my %INFO;
	
	if ( $containers->[0] eq 'all' ) {
		@$containers = split(/\n/, $self->{server}->capture("lxc-ls -f | awk '{print \$1}' | grep -v NAME"));
	}
	
	for my $container (@$containers) {
		my @resp = $self->{server}->capture2({timeout => 1}, "lxc-start -n $container");
		map {chomp $_; $INFO{$container} = $_;} @resp;
	}
	
	# $self->{server} = \%INFO;
	# return $self->{server};
	return \%INFO;
}

sub freeze {
	my $self = shift;
	my $containers = shift;
	my %INFO;
	
	if ( $containers->[0] eq 'all' ) {
		@$containers = split(/\n/, $self->{server}->capture("lxc-ls -f | awk '{print \$1}' | grep -v NAME"));
	}
	
	for my $container (@$containers) {
		my @resp = $self->{server}->capture2({timeout => 1}, "lxc-freeze -n $container");
		map {chomp $_; $INFO{$container} = $_;} @resp;
	}
	
	# $self->{server} = \%INFO;
	# return $self->{server};
	return \%INFO;
}

sub unfreeze {
	my $self = shift;
	my $containers = shift;
	my %INFO;
	
	if ( $containers->[0] eq 'all' ) {
		@$containers = split(/\n/, $self->{server}->capture("lxc-ls -f | awk '{print \$1}' | grep -v NAME"));
	}
	
	for my $container (@$containers) {
		my @resp = $self->{server}->capture2({timeout => 1}, "lxc-unfreeze -n $container");
		map {chomp $_; $INFO{$container} = $_;} @resp;
	}
	
	# $self->{server} = \%INFO;
	# return $self->{server};
	return \%INFO;
}

sub destroy {
	my $self = shift;
	my $containers = shift;
	my $force = shift;
	my %INFO;
	
	if ( $containers->[0] eq 'all' ) {
		@$containers = split(/\n/, $self->{server}->capture("lxc-ls -f | awk '{print \$1}' | grep -v NAME"));
	}
	
	$force = $force eq 'force' ? '-f' : '';
	
	for my $container (@$containers) {
		my @resp = $self->{server}->capture2({timeout => 1}, "lxc-destroy -n $container $force");
		map {chomp $_; $INFO{$container} = $_;} @resp;
	}
	
	# $self->{server} = \%INFO;
	# return $self->{server};
	return \%INFO;
}

sub remoteCopy {
	my $self = shift;
	my $data = shift;
	
	my $command = $self->{server}->capture2({timeout => $data->{timeOut}}, "/usr/bin/lxccp $data->{Name} $data->{remoteHost} $data->{passwd}");
	
	return $command;
}

sub localCopy {
	my $self = shift;
	my $data = shift;
	
	my $command = $self->{server}->capture2({timeout => 300}, "lxc-copy -n $data->{OriginName} -N $data->{TargetName}");
	
	return $command;
}

sub updateLocalCopy {
	my $self = shift;
	my $data = shift;
	my %INFO;
	
	$INFO{$data->{Name}}{rootfs} = "/var/lib/lxc/$data->{Name}/rootfs";
	
	####	Network configuration (experimental)
	if ( $data->{proto} and $data->{iface} ) {
		unless ( $data->{proto} =~ /static|dhcp/ ) { $data->{proto} = 'dhcp' }
		unless ( $data->{iface} ) { $data->{iface} = 'eth0' }
		unless ( $data->{gateway} ) { $data->{gateway} = '192.168.1.1' }
		unless ( $data->{netmask} ) { $data->{netmask} = '255.255.255.0' }
		unless ( $data->{network} ) { $data->{network} = '192.168.1.0' }
		unless ( $data->{broadcast} ) { $data->{broadcast} = '192.168.1.255' }
		
		my $netScript;
		if ( $data->{Distro} =~ /^ubuntu$|^debian$/ ) {#################################################################################	UBUNTU
			$netScript = qq~
#The loopback network interface
auto lo
iface lo inet loopback

#The Primary interface
auto $data->{iface}
iface $data->{iface} inet $data->{proto}~;
$netScript .= qq~
  address $data->{ipAddr}
  netmask $data->{netmask}
  network $data->{network}
  broadcast $data->{broadcast}
  gateway $data->{gateway}
  dns-nameservers 8.8.8.8 4.4.4.4
~ if $data->{proto} eq 'static';
		
			$self->{server}->capture2({timeout => 1}, "echo '$netScript' > $INFO{$data->{Name}}{rootfs}/etc/network/interfaces");
		}
		elsif ( $data->{Distro} =~ /^centos$|^fedora$|^oracle$/ ) {#####################################################################	CENTOS
			$netScript = qq~BOOTPROTO=$data->{proto}
DEVICE=$data->{iface}
ONBOOT=yes
HOSTNAME=$data->{hostname}
NM_CONTROLLED=no
TYPE=Ethernet
MTU=
DHCP_HOSTNAME=`hostname`~;
$netScript .= qq~
IPADDR=$data->{ipAddr}
NETMASK=$data->{netmask}
GATEWAY=$data->{gateway}
#DNS1=8.8.8.8
#DNS2=8.8.4.4
~ if $data->{proto} eq 'static';

			$self->{server}->capture2({timeout => 1}, "echo '$netScript' > $INFO{$data->{Name}}{rootfs}/etc/sysconfig/network-scripts/ifcfg-$data->{iface}");
		}
		elsif ( $data->{Distro} eq 'opensuse' ) {#######################################################################################	OPENSUSE
			$netScript = qq~BOOTPROTO='$data->{proto}'
NAME='Ethernet Controller'
STARTMODE='auto'
USERCONTROL='no'~;
$netScript .= qq~
BROADCAST='$data->{broadcast}'
ETHTOOL_OPTIONS=''
IPADDR='$data->{ipAddr}'
MTU=''
NETWORK='$data->{network}'
REMOTE_IPADDR=''
PREFIXLEN=''
~ if $data->{proto} eq 'static';

			$self->{server}->capture2({timeout => 1}, "echo <<EOF\n$netScript\nEOF > $INFO{$data->{Name}}{rootfs}/etc/sysconfig/network/ifcfg-$data->{iface}");
			
			$self->{server}->capture2({timeout => 1}, "echo 'default $data->{gateway}' > $INFO{$data->{Name}}{rootfs}/etc/sysconfig/network/routes");
		}										#######################################################################################
	}
	
	$self->{server}->capture2({timeout => 1}, "echo '$data->{hostname}' > $INFO{$data->{Name}}{rootfs}/etc/hostname");
	
	$self->{server}->capture2({timeout => 1}, "echo '127.0.0.1 localhost $data->{hostname}' > $INFO{$data->{Name}}{rootfs}/etc/hosts");
	####	Network configuration (experimental)
	
	my $rootfs = '/var/lib/lxc/' . $data->{Name};
	my $swap ;
	$swap = ($data->{memory} * 4) . 'M' if $data->{memory} =~ /M$/;
	$swap = ($data->{memory} * 4) . 'G' if $data->{memory} =~ /G$/;
	
	my $date = date();
	my $chgmem = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.cgroup\\.memory\\.limit_in_bytes.+\n/lxc\\.cgroup\\.memory\\.limit_in_bytes = $data->{memory}\n/' $rootfs/config~);
	my $chgswap = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.cgroup\\.memory\\.memsw\\.limit_in_bytes.+\n/lxc\\.cgroup\\.memory\\.memsw\\.limit_in_bytes = $swap\n/' $rootfs/config~);
	
	my $chghostname = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.utsname.+\n/lxc\\.utsname = $data->{hostname}\n/' $rootfs/config~);
	my $chghostnam1 = $self->{server}->capture("echo '$data->{hostname}' > $rootfs/rootfs/etc/hostname");
	
	my $autostart = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.start\\.auto.+\n/lxc\\.start\\.auto = $data->{startAuto}\n/' $rootfs/config~);
	my $autostart = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.start\\.delay.+\n/lxc\\.start\\.delay = $data->{startDelay}\n/' $rootfs/config~);
	
	return 0;
}

sub create {
	my $self = shift;
	my $data = shift;
	my %INFO;
	
	# print "Creando contenedor $data->{Name}\n";
	my @resp = $self->{server}->capture2({timeout => $data->{TimeOut}}, "lxc-create -t download -n $data->{Name} -- -d $data->{Distro} -r $data->{Release} -a $data->{Arch}");
	# print "Se creo contenedor $data->{Name}\n";
	
	# $self->{server}->capture("tar -xzf /var/cache/lxc/$data->{Distro}$data->{Release}$data->{Arch}.tar.gz -C /var/lib/lxc/");
	
	# $self->{server}->capture("mv -f /var/lib/lxc/$data->{Distro}$data->{Release}$data->{Arch}/config /var/lib/lxc/$data->{Name}/");
	
	# $self->{server}->capture("mv -f /var/lib/lxc/$data->{Distro}$data->{Release}$data->{Arch}/rootfs/* /var/lib/lxc/$data->{Name}/rootfs/");
	
	# $self->{server}->capture("rm -Rf /var/lib/lxc/$data->{Distro}$data->{Release}$data->{Arch}");
	
	# %INFO = $self->addConf($data->{Name});
	$INFO{$data->{Name}}{rootfs} = "/var/lib/lxc/$data->{Name}/rootfs";
	
	sleep 1;
	
	####	Network configuration (experimental)
	if ( $data->{proto} and $data->{iface} ) {
		unless ( $data->{proto} =~ /static|dhcp/ ) { $data->{proto} = 'dhcp' }
		unless ( $data->{iface} ) { $data->{iface} = 'eth0' }
		unless ( $data->{gateway} ) { $data->{gateway} = '192.168.1.1' }
		unless ( $data->{netmask} ) { $data->{netmask} = '255.255.255.0' }
		unless ( $data->{network} ) { $data->{network} = '192.168.1.0' }
		unless ( $data->{broadcast} ) { $data->{broadcast} = '192.168.1.255' }
		
		my $netScript;
		if ( $data->{Distro} =~ /^ubuntu$|^debian$/ ) {#################################################################################	UBUNTU
			$netScript = qq~
#The loopback network interface
auto lo
iface lo inet loopback

#The Primary interface
auto $data->{iface}
iface $data->{iface} inet $data->{proto}~;
$netScript .= qq~
  address $data->{ipAddr}
  netmask $data->{netmask}
  network $data->{network}
  broadcast $data->{broadcast}
  gateway $data->{gateway}
  dns-nameservers 8.8.8.8 4.4.4.4
~ if $data->{proto} eq 'static';
		
			$self->{server}->capture2({timeout => 1}, "echo '$netScript' > $INFO{$data->{Name}}{rootfs}/etc/network/interfaces");
			
			my $sshAutoInstall = '#!/bin/sh\n';
			$sshAutoInstall .= 'apt-get update\n';
			$sshAutoInstall .= 'apt-get install openssh-server -y\n';
			$sshAutoInstall .= '#Modificar PermitRootLogin a yes:\n';
			$sshAutoInstall .= "perl -pi -e 's/prohibit-password/yes/' /etc/ssh/sshd_config".'\n';
			$sshAutoInstall .= "perl -pi -e 's/without-password/yes/' /etc/ssh/sshd_config".'\n';
			$sshAutoInstall .= '/etc/init.d/ssh restart\n';
			$sshAutoInstall .= "sed -i 's/\\/firstinit//' /etc/rc.local".'\n';
			$sshAutoInstall .= 'rm -f /firstinit\n';
			$sshAutoInstall .= 'exit;\n';
			
			$self->{server}->capture2({timeout => 1}, "echo -e \"$sshAutoInstall\" > $INFO{$data->{Name}}{rootfs}/firstinit");
			$self->{server}->capture2({timeout => 1}, "chmod 755 $INFO{$data->{Name}}{rootfs}/firstinit");
			
			# $self->{server}->capture2({timeout => 1}, "echo '/firstinit' >> $INFO{$data->{Name}}{rootfs}/etc/rc.local");
			$self->{server}->capture(qq~perl -pi -e 's/\^exit 0/\\/firstinit\nexit 0/' $INFO{$data->{Name}}{rootfs}/etc/rc.local~);
			
		}
		elsif ( $data->{Distro} =~ /^centos$|^fedora$|^oracle$/ ) {#####################################################################	CENTOS
			$netScript = qq~BOOTPROTO=$data->{proto}
DEVICE=$data->{iface}
ONBOOT=yes
HOSTNAME=$data->{hostname}
NM_CONTROLLED=no
TYPE=Ethernet
MTU=
DHCP_HOSTNAME=`hostname`~;
$netScript .= qq~
IPADDR=$data->{ipAddr}
NETMASK=$data->{netmask}
GATEWAY=$data->{gateway}
#DNS1=8.8.8.8
#DNS2=8.8.4.4
~ if $data->{proto} eq 'static';

			$self->{server}->capture2({timeout => 1}, "echo '$netScript' > $INFO{$data->{Name}}{rootfs}/etc/sysconfig/network-scripts/ifcfg-$data->{iface}");
			
			my $sshAutoInstall = '#!/bin/sh\n';
			$sshAutoInstall .= '/bin/sleep 10\n';		####	For compatibility with CentOS 7
			$sshAutoInstall .= '/usr/bin/yum -y install openssh-server\n';
			$sshAutoInstall .= 'chkconfig sshd on\n';
			$sshAutoInstall .= 'service sshd start\n';
			$sshAutoInstall .= "sed -i 's/\\/firstinit//' /etc/rc.d/rc.local".'\n';
			$sshAutoInstall .= 'rm -f /firstinit\n';
			$sshAutoInstall .= 'chage -d -1 root\n';
			$sshAutoInstall .= 'exit;\n';
			
			$self->{server}->capture2({timeout => 1}, "echo -e \"$sshAutoInstall\" > $INFO{$data->{Name}}{rootfs}/firstinit");
			$self->{server}->capture2({timeout => 1}, "chmod 755 $INFO{$data->{Name}}{rootfs}/firstinit");
			$self->{server}->capture2({timeout => 1}, "chmod 755 $INFO{$data->{Name}}{rootfs}/etc/rc.d/rc.local");	####	For compatibility with CentOS 7
			
			$self->{server}->capture2({timeout => 1}, "echo '/firstinit' >> $INFO{$data->{Name}}{rootfs}/etc/rc.d/rc.local");
			
		}
		elsif ( $data->{Distro} eq 'opensuse' ) {#######################################################################################	OPENSUSE
			$netScript = qq~BOOTPROTO='$data->{proto}'
NAME='Ethernet Controller'
STARTMODE='auto'
USERCONTROL='no'~;
$netScript .= qq~
BROADCAST='$data->{broadcast}'
ETHTOOL_OPTIONS=''
IPADDR='$data->{ipAddr}'
MTU=''
NETWORK='$data->{network}'
REMOTE_IPADDR=''
PREFIXLEN=''
~ if $data->{proto} eq 'static';

			$self->{server}->capture2({timeout => 1}, "echo <<EOF\n$netScript\nEOF > $INFO{$data->{Name}}{rootfs}/etc/sysconfig/network/ifcfg-$data->{iface}");
			
			$self->{server}->capture2({timeout => 1}, "echo 'default $data->{gateway}' > $INFO{$data->{Name}}{rootfs}/etc/sysconfig/network/routes");
		}										#######################################################################################
	}
	
	$self->{server}->capture2({timeout => 1}, "echo '$data->{hostname}' > $INFO{$data->{Name}}{rootfs}/etc/hostname");
	
	$self->{server}->capture2({timeout => 1}, "echo '127.0.0.1 localhost $data->{hostname}' > $INFO{$data->{Name}}{rootfs}/etc/hosts");
	####	Network configuration (experimental)
	
	#### Add to "config" file, some specific configurations
	my $configFile = $INFO{$data->{Name}}{rootfs};
	$configFile =~ s/rootfs/config/;
	
	# my $rand_mac_addr = rand_mac_addr();
	
	# my $config = qq~
# #Container specific configuration
# lxc.rootfs = /var/lib/lxc/$data->{Name}/rootfs
# lxc.rootfs.backend = dir
# lxc.utsname = $data->{Name}

# #Network configuration
# lxc.network.type = veth
# lxc.network.link = lxcbr0
# lxc.network.flags = up
# lxc.network.hwaddr = $rand_mac_addr

# #Miquiloni config
# ~;
	my $config = qq~

# Miquiloni config
~;
	my $swap ;
	$swap = ($data->{memory} * 4) . 'M' if $data->{memory} =~ /M$/;
	$swap = ($data->{memory} * 4) . 'G' if $data->{memory} =~ /G$/;
	
	$config .= qq~lxc.cgroup.memory.limit_in_bytes = $data->{memory}\n~;
	$config .= qq~lxc.cgroup.memory.memsw.limit_in_bytes = $swap\n~;
	$config .= qq~lxc.cgroup.cpuset.cpus = $data->{cpu}\n~;
	# $config .= qq~limits.cpu.allowance = $data->{percentCpu}ms/100ms\n~ if $data->{percentCpu} ne '100';
	$config .= qq~limits.cpu.allowance = $data->{percentCpu}ms/100ms\n~;
	$config .= qq~lxc.start.auto = $data->{startAuto}\n~;
	$config .= qq~lxc.start.delay = $data->{startDelay}\n~;
	
	$self->{server}->capture2({timeout => 1}, "echo -e \"$config\" >> $configFile");
	
	$self->{server}->capture2({timeout => 1}, "/bin/mkdir $INFO{$data->{Name}}{rootfs}/root/.ssh");
	
	my $keyContent = `cat $data->{keypair}.pub`;
	$self->{server}->capture2({timeout => 1}, "echo '$keyContent' > $INFO{$data->{Name}}{rootfs}/root/.ssh/authorized_keys");
	
	$self->{server}->capture2({timeout => 1}, "chmod -R 640 $INFO{$data->{Name}}{rootfs}/root/.ssh");
	
	return 0;
}



sub rand_mac_addr {
	my @a = qw(0 1 2 3 4 5 6 7 8 9 a b c d e f);
	
	my $rand = '00';
	for ( 0 .. 4 ) {
		$rand .= ':';
		for ( 0 .. 1 ) {
			$rand .= $a[int rand 16];
		}
	}
	
	return $rand;
}


sub date {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900;
	$mon ++;
	$mon = "0$mon" if $mon < 10;
	$mday = "0$mday" if $mday < 10;
	$hour = "0$hour" if $hour < 10;
	$min = "0$min" if $min < 10;
	$sec = "0$sec" if $sec < 10;
	return "$year$mon$mday$hour$min$sec";
}


sub update {
	my $self = shift;
	my $data = shift;
	
	my $rootfs = '/var/lib/lxc/' . $data->{Name};
	my $swap ;
	$swap = ($data->{memory} * 4) . 'M' if $data->{memory} =~ /M$/;
	$swap = ($data->{memory} * 4) . 'G' if $data->{memory} =~ /G$/;
	
	my $date = date();
	my $chgmem = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.cgroup\\.memory\\.limit_in_bytes.+\n/lxc\\.cgroup\\.memory\\.limit_in_bytes = $data->{memory}\n/' $rootfs/config~);
	my $chgswap = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.cgroup\\.memory\\.memsw\\.limit_in_bytes.+\n/lxc\\.cgroup\\.memory\\.memsw\\.limit_in_bytes = $swap\n/' $rootfs/config~);
	
	my $chghostname = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.utsname.+\n/lxc\\.utsname = $data->{hostname}\n/' $rootfs/config~);
	my $chghostnam1 = $self->{server}->capture("echo '$data->{hostname}' > $rootfs/rootfs/etc/hostname");
	
	my $autostart = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.start\\.auto.+\n/lxc\\.start\\.auto = $data->{startAuto}\n/' $rootfs/config~);
	my $autostart = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.start\\.delay.+\n/lxc\\.start\\.delay = $data->{startDelay}\n/' $rootfs/config~);
	
	if ( $data->{proto} and $data->{iface} ) {
		unless ( $data->{proto} =~ /static|dhcp/ ) { $data->{proto} = 'dhcp' }
		unless ( $data->{iface} ) { $data->{iface} = 'eth0' }
		unless ( $data->{gateway} ) { $data->{gateway} = '192.168.1.254' }
		unless ( $data->{netmask} ) { $data->{netmask} = '255.255.255.0' }
		unless ( $data->{network} ) { $data->{network} = '192.168.1.0' }
		unless ( $data->{broadcast} ) { $data->{broadcast} = '192.168.1.255' }
		
		my $netScript;
		if ( $data->{Distro} =~ /^ubuntu$|^debian$/ ) {#################################################################################	UBUNTU
			$netScript = qq~
#The loopback network interface
auto lo
iface lo inet loopback

#The Primary interface
auto $data->{iface}
iface $data->{iface} inet $data->{proto}~;
$netScript .= qq~
  address $data->{ipAddr}
  netmask $data->{netmask}
  network $data->{network}
  broadcast $data->{broadcast}
  gateway $data->{gateway}
  dns-nameservers 8.8.8.8 4.4.4.4
~ if $data->{proto} eq 'static';
		
			$self->{server}->capture2({timeout => 1}, "echo '$netScript' > $rootfs/rootfs/etc/network/interfaces");
		}
		elsif ( $data->{Distro} =~ /^centos$|^fedora$|^oracle$/ ) {#####################################################################	CENTOS
			$netScript = qq~BOOTPROTO=$data->{proto}
DEVICE=$data->{iface}
ONBOOT=yes
HOSTNAME=$data->{hostname}
NM_CONTROLLED=no
TYPE=Ethernet
MTU=
DHCP_HOSTNAME=`hostname`~;
$netScript .= qq~
IPADDR=$data->{ipAddr}
NETMASK=$data->{netmask}
GATEWAY=$data->{gateway}
#DNS1=8.8.8.8
#DNS2=8.8.4.4
~ if $data->{proto} eq 'static';

			$self->{server}->capture2({timeout => 1}, "echo '$netScript' > $rootfs/rootfs/etc/sysconfig/network-scripts/ifcfg-$data->{iface}");
		}
		elsif ( $data->{Distro} eq 'opensuse' ) {#######################################################################################	OPENSUSE
			$netScript = qq~BOOTPROTO='$data->{proto}'
NAME='Ethernet Controller'
STARTMODE='auto'
USERCONTROL='no'~;
$netScript .= qq~
BROADCAST='$data->{broadcast}'
ETHTOOL_OPTIONS=''
IPADDR='$data->{ipAddr}'
MTU=''
NETWORK='$data->{network}'
REMOTE_IPADDR=''
PREFIXLEN=''
~ if $data->{proto} eq 'static';

			$self->{server}->capture2({timeout => 1}, "echo <<EOF\n$netScript\nEOF > $rootfs/rootfs/etc/sysconfig/network/ifcfg-$data->{iface}");
			
			$self->{server}->capture2({timeout => 1}, "echo 'default $data->{gateway}' > $rootfs/rootfs/etc/sysconfig/network/routes");
		}										#######################################################################################
	}
}

sub update_migrated {
	my $self = shift;
	my $data = shift;
	
	my $rootfs = '/var/lib/lxc/' . $data->{Name};
	my $swap ;
	$swap = ($data->{memory} * 4) . 'M' if $data->{memory} =~ /M$/;
	$swap = ($data->{memory} * 4) . 'G' if $data->{memory} =~ /G$/;
	
	$data->{percentCpu} = $data->{percentCpu} . 'ms/100ms';
	
	my $date = date();
	my $chgmem = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.cgroup\\.memory\\.limit_in_bytes.+\n/lxc\\.cgroup\\.memory\\.limit_in_bytes = $data->{memory}\n/' $rootfs/config~);
	my $chgswap = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.cgroup\\.memory\\.memsw\\.limit_in_bytes.+\n/lxc\\.cgroup\\.memory\\.memsw\\.limit_in_bytes = $swap\n/' $rootfs/config~);
	
	my $cpu = $self->{server}->capture(qq~perl -pi.$date -e 's/lxc\\.cgroup\\.cpuset\\.cpus.+\n/lxc\\.cgroup\\.cpuset\\.cpus = $data->{cpu}\n/' $rootfs/config~);
	my $percentCpu = $self->{server}->capture(qq~perl -pi.$date -e 's!limits\\.cpu\\.allowance.+\n!limits\\.cpu\\.allowance = $data->{percentCpu}\n!' $rootfs/config~);
}


1;
