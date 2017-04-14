%MSG = loadLang('accounts');

my $html;
$html .= qq~<div class="contentTitle">$MSG{User_Accounts}</div>~ unless $input{'shtl'};


if ( $input{submod} eq 'delete_record' ) {
	connected();
	$dbh->do("LOCK TABLES users WRITE");
	my $sth = $dbh->prepare(qq~DELETE FROM users WHERE idUser = '$input{idUser}'~);
	$sth->execute();
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	
	$dbh->do("LOCK TABLES permissions WRITE");
	my $sth = $dbh->prepare(qq~DELETE FROM permissions WHERE idUser = '$input{idUser}'~);
	$sth->execute();
	$sth->finish;
	$dbh->do("UNLOCK TABLES");
	
	$dbh->disconnect if $dbh;
	
	my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
	$log->Log("DELETE:Account:idUser=$input{idUser}");
	
	print "Location: index.cgi?mod=accounts\n\n";
}


if ( $input{submod} eq 'save_record' ) {
	my $prepare;
	
	if ( $input{pwd1} ) {
		if ( $input{pwd1} eq $input{pwd2} ) {
			# $prepare = "UPDATE users SET name=?, lastName=?, maidenName=?, idEmployee=?, email=?, secondaryEmail=?, phone=?, secondaryPhone=?, costCenterId=?, groupId=?, secondaryGroupId=?, theme=?, language=?, active=?, password=? WHERE idUser=?";
			use Crypt::Babel;
			my $crypt = new Babel;
			my $pwdEnc = $crypt->encode($input{pwd1}, $encKey);
			
			$input{costCenterId} = '0' unless $input{costCenterId};
			$input{groupId} = '0' unless $input{groupId};
			$input{secondaryGroupId} = '0' unless $input{secondaryGroupId};
			
			connected();
			my $sth = $dbh->prepare("UPDATE users SET 
			password='$pwdEnc',
			name='$input{name}',
			lastName='$input{lastName}',
			mothersLastName='$input{mothersLastName}',
			idEmployee='$input{idEmployee}',
			email='$input{email}',
			secondaryEmail='$input{secondaryEmail}',
			phone='$input{phone}',
			secondaryPhone='$input{secondaryPhone}',
			costCenterId='$input{costCenterId}',
			groupId='$input{groupId}',
			secondaryGroupId='$input{secondaryGroupId}',
			theme='$input{theme}',
			language='$input{language}',
			active='$input{active}' 
			WHERE idUser='$input{idUser}'");
			$sth->execute();
			$sth->finish;
			
			$input{lxcservers} = '0' unless $input{lxcservers};
			$input{lxcservers_edit} = '0' unless $input{lxcservers_edit};
			$input{provisioning} = '0' unless $input{provisioning};
			$input{accounts} = '0' unless $input{accounts};
			$input{accounts_edit} = '0' unless $input{accounts_edit};
			$input{containers} = '0' unless $input{containers};
			$input{containers_edit} = '0' unless $input{containers_edit};
			$input{sectors} = '0' unless $input{sectors};
			$input{migration} = '0' unless $input{migration};
			$input{keypairs} = '0' unless $input{keypairs};
			$input{distros} = '0' unless $input{distros};
			
			my $sth1 = $dbh->prepare("UPDATE permissions SET 
			lxcservers='$input{lxcservers}',
			lxcservers_edit='$input{lxcservers_edit}',
			provisioning='$input{provisioning}',
			accounts='$input{accounts}',
			accounts_edit='$input{accounts_edit}',
			containers='$input{containers}',
			containers_edit='$input{containers_edit}',
			sectors='$input{sectors}',
			migration='$input{migration}',
			keypairs='$input{keypairs}',
			distros='$input{distros}'
			WHERE idUser='$input{idUser}'");
			$sth1->execute();
			$sth1->finish;
			
			$dbh->disconnect if $dbh;
			
			my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
			$log->Log("UPDATE:Account:idUser=$input{idUser};name=$input{name};lastName=$input{lastName};mothersLastName=$input{mothersLastName};idEmployee=$input{idEmployee};email=$input{email};secondaryEmail=$input{secondaryEmail};phone=$input{phone};secondaryPhone=$input{secondaryPhone};costCenterId=$input{costCenterId};groupId=$input{groupId};secondaryGroupId=$input{secondaryGroupId};theme=$input{theme};language=$input{language};active=$input{active};lxcservers=$input{lxcservers};lxcservers_edit=$input{lxcservers_edit};provisioning=$input{provisioning};accounts=$input{accounts};accounts_edit=$input{accounts_edit};containers=$input{containers};containers_edit=$input{containers_edit};sectors=$input{sectors};migration=$input{migration};keypairs=$input{keypairs};distros=$input{distros}");
			
			print "Location: index.cgi?mod=accounts&idUser=$input{idUser}\n\n";
			
			
		} else {
			$html .= qq~<font color="#BB0000">$MSG{Passwords_does_not_match}</font>~;
		}
	} else {
		$html .= qq~<font color="#BB0000">$MSG{Passwords_are_mandatory}</font><br /><br /><br /><br />~;
	}
}


if ( $input{submod} eq 'new_record' ) {
	
	if ( $input{username} and $input{pwd1} and $input{pwd2} ) {
		if ( $input{pwd1} eq $input{pwd2} ) {
			
			connected();
			$sth = $dbh->prepare("SELECT idUser FROM users WHERE username = '$input{username}'");
			$sth->execute();
			my ($idUserTest) = $sth->fetchrow_array;
			$sth->finish;
			
			unless ($idUserTest) {
				use Crypt::Babel;
				my $crypt = new Babel;
				my $pwdEnc = $crypt->encode($input{pwd1}, $encKey);
				
				$input{costCenterId} = '0' unless $input{costCenterId};
				$input{groupId} = '0' unless $input{groupId};
				$input{secondaryGroupId} = '0' unless $input{secondaryGroupId};
				
				# $dbh->do("LOCK TABLES users WRITE");
				my $insert_string = qq~INSERT INTO users (
				username, password, name, lastName, mothersLastName, idEmployee, email, secondaryEmail, phone, secondaryPhone, costCenterId, groupId, secondaryGroupId, theme, language, active
				) VALUES (
				'$input{username}',
				'$pwdEnc',
				'$input{name}',
				'$input{lastName}', 
				'$input{mothersLastName}',
				'$input{idEmployee}',
				'$input{email}',
				'$input{secondaryEmail}',
				'$input{phone}', 
				'$input{secondaryPhone}',
				'$input{costCenterId}',
				'$input{groupId}',
				'$input{secondaryGroupId}',
				'$input{theme}', 
				'$input{language}',
				'$input{active}')~;
				$sth = $dbh->prepare($insert_string);
				$sth->execute();
				$sth->finish;
				# $dbh->do("UNLOCK TABLES");
						$html .= "$insert_string<br>";
				
				$sth = $dbh->prepare("SELECT idUser FROM users WHERE username = '$input{username}'");
				$sth->execute();
				my ($idUserNew) = $sth->fetchrow_array;
				$sth->finish;
				
				$input{lxcservers} = '0' unless $input{lxcservers};
				$input{lxcservers_edit} = '0' unless $input{lxcservers_edit};
				$input{provisioning} = '0' unless $input{provisioning};
				$input{accounts} = '0' unless $input{accounts};
				$input{accounts_edit} = '0' unless $input{accounts_edit};
				$input{containers} = '0' unless $input{containers};
				$input{containers_edit} = '0' unless $input{containers_edit};
				$input{sectors} = '0' unless $input{sectors};
				$input{migration} = '0' unless $input{migration};
				$input{keypairs} = '0' unless $input{keypairs};
				$input{distros} = '0' unless $input{distros};
				
				$insert_string = qq~INSERT INTO permissions (
				idUser, lxcservers, lxcservers_edit, provisioning, accounts, accounts_edit, containers, containers_edit, sectors, migration, keypairs, distros
				) VALUES (
				'$idUserNew',
				'$input{lxcservers}',
				'$input{lxcservers_edit}',
				'$input{provisioning}',
				'$input{accounts}',
				'$input{accounts_edit}',
				'$input{containers}',
				'$input{containers_edit}',
				'$input{sectors}',
				'$input{migration}',
				'$input{keypairs}',
				'$input{distros}')~;
				$sth = $dbh->prepare("$insert_string");
				$sth->execute();
				$sth->finish;
						$html .= "<br>$insert_string<br><br>";
				
				$dbh->disconnect if $dbh;
				
				my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
				$log->Log("NEW:Account:idUser=$input{idUser};username=$input{username};name=$input{name};lastName=$input{lastName};mothersLastName=$input{mothersLastName};idEmployee=$input{idEmployee};email=$input{email};secondaryEmail=$input{secondaryEmail};phone=$input{phone};secondaryPhone=$input{secondaryPhone};costCenterId=$input{costCenterId};groupId=$input{groupId};secondaryGroupId=$input{secondaryGroupId};theme=$input{theme};language=$input{language};active=$input{active};lxcservers=$input{lxcservers};lxcservers_edit=$input{lxcservers_edit};provisioning=$input{provisioning};accounts=$input{accounts};accounts_edit=$input{accounts_edit};containers=$input{containers};containers_edit=$input{containers_edit};sectors=$input{sectors};migration=$input{migration};keypairs=$input{keypairs};distros=$input{distros}");
				
				print "Location: index.cgi?mod=accounts\n\n";
				
			} else {
				$html .= qq~<font color="#BB0000">$MSG{Username_alredy_exists}</font><br /><br /><br /><br />~;
			}
		} else {
			$html .= qq~<font color="#BB0000">$MSG{Passwords_does_not_match}</font><br /><br /><br /><br />~;
		}
	} else {
		$html .= qq~<font color="#BB0000">$MSG{User_Name_and_Passwords_are_mandatory}</font><br /><br /><br /><br />~;
	}
}


$sth = $dbh->prepare("SELECT * FROM users WHERE username NOT IN ('Guest', 'admin') ORDER BY username");
$sth->execute();
my $users = $sth->fetchall_arrayref;
$sth->finish;
$dbh->disconnect if ($dbh);


$html .= qq~
<div id="grid" style="width: 100%; height: 400px;"></div>

<script>
\$(function () {
    \$('\#grid').w2grid({
        name: 'grid',
        header: '$MSG{List_of_Accounts}',
        show: {
			header    : true,
            footer    : true,
            toolbar   : true
        },
        columns: [
            { field: 'username', caption: '$MSG{User_Name}', size: '15%', sortable: true, searchable: true },
            { field: 'name', caption: '$MSG{Name}', size: '20%', sortable: true, searchable: true },
            { field: 'lastName', caption: '$MSG{Last_Name}', size: '20%', sortable: true, searchable: true },
            { field: 'mothersLastName', caption: "$MSG{Mothers_Last_Name}", size: '20%', sortable: true, searchable: true },
            { field: 'email', caption: '$MSG{Email}', size: '20%', sortable: true, searchable: true },
            { field: 'active', caption: '$MSG{Active}', size: '5%' },
        ],
        records: [
        ~;
        
		for my $i ( 0 .. $#{$users} ) {
			$users->[$i][16] = $users->[$i][16] eq '1' ? 'Yes' : 'No';
			$html .= qq~{
				recid: $users->[$i][0],
				username: '$users->[$i][1]',
				name: '$users->[$i][3]',
				lastName: '$users->[$i][4]',
				mothersLastName: '$users->[$i][5]',
				email: '$users->[$i][7]',
				active: '$users->[$i][16]',
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
                    var html_link = 'launcher.cgi?mod=accounts_edit&idUser='+recid;
                    window.open(html_link, 'edition_frame');
                } else {
					var html_link = 'launcher.cgi?mod=accounts_edit';
                    window.open(html_link, 'edition_frame');
                    form.clear();
                }
            }
        }
    });
});
</script>

<iframe name="edition_frame" src="launcher.cgi?mod=accounts_edit&idUser=$input{idUser}" class="edition_frame" onload="this.style.height=this.contentDocument.body.scrollHeight +'px';"></iframe>

<br />
<br />
~;



return $html;
1;
