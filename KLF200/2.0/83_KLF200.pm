##############################################################################
#
#     83_KLF200.pm
#     Copyright by Stefan Bünnig buennerbernd
#
##############################################################################

package main;

use strict;
use warnings;
use DevIo; # load DevIo.pm if not already loaded
use Data::Dumper;

# called upon loading the module KLF200
sub KLF200_Initialize($) {
  my ($hash) = @_;

  $hash->{DefFn}    = "KLF200_Define";
  $hash->{UndefFn}  = "KLF200_Undef";
  $hash->{SetFn}    = "KLF200_Set";
  $hash->{ReadFn}   = "KLF200_Read";
  $hash->{ReadyFn}  = "KLF200_Ready";
  $hash->{WriteFn}  = "KLF200_Write";
	$hash->{AttrList} = "autoReboot:0,1 " . $readingFnAttributes;
  
  $hash->{Clients} = "KLF200Node.*";
  $hash->{MatchList} = { "1:KLF200Node" => ".*" };
  
}

# called when a new definition is created (by hand or from configuration read on FHEM startup)
sub KLF200_Define($$) {
  my ($hash, $def) = @_;
  my @a = split("[ \t]+", $def);

#  if($a != 4) {
#    my $msg = "wrong syntax: define <name> KLF200 <host> <pwfile>";
#    Log(2, $msg);
#    return $msg;
#  }
    
  my $name = $a[0];
  # $a[1] is always equals the module name "KLF200"
  
  # first argument is the hostname or IP address of the device (e.g. "192.168.1.120")
  my $dev = $a[2]; 
  # add a default port (51200), if not explicitly given by user
  $dev .= ':51200' if(not $dev =~ m/:\d+$/);
  $hash->{DeviceName} = $dev;
  $hash->{SSL} = 1;
  $hash->{TIMEOUT} = 10; #default is 3 
  
  my $pwfile = $a[3]; 
  $hash->{"pwfile"}= $pwfile;
  
  # close connection if maybe open (on definition modify)
  DevIo_CloseDev($hash) if(DevIo_IsOpen($hash));  
  
  # open connection with custom init and error callback function (non-blocking connection establishment)
  DevIo_OpenDev($hash, 0, "KLF200_Init", "KLF200_Callback"); 

  KLF200_InitTexts($hash);
 
  return undef;
}

sub KLF200_InitTexts($) {
  my ($hash) = @_;
   
  $hash->{Const}->{ErrorNumber} = {
    0 => "Not further defined error.",
    1 => "Unknown Command or command is not accepted at this state.",
    3 => "ERROR on Frame Structure.",
    7 => "Busy. Try again later.",
    8 => "Bad system table index.",
    12 => "Not authenticated.",
  };
  $hash->{Const}->{Status} = {
    0 => "OK - Request accepted",
    1 => "Error – Invalid parameter",
    2 => "Error – Request rejected",
  };
}

sub KLF200_GetText($$$) {
  my ($hash, $const, $id) = @_;
  
  my $text = $hash->{Const}->{$const}->{$id};
  if (not defined($text)) {return $id};
  
  return $text;
}

# called when definition is undefined 
# (config reload, shutdown or delete of definition)
sub KLF200_Undef($$) {
  my ($hash, $name) = @_;
 
  # close the connection 
  DevIo_CloseDev($hash);
  
  return undef;
}

# called repeatedly if device disappeared
sub KLF200_Ready($) {
  my ($hash) = @_;
  
  # try to reopen the connection in case the connection is lost
  return DevIo_OpenDev($hash, 1, "KLF200_Init", "KLF200_Callback"); 
}

# called when data was received
sub KLF200_Read($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  # read the available data
  my $buf = DevIo_SimpleRead($hash);
  
  # stop processing if no data is available (device disconnected)
  return if(!defined($buf));
  
  RemoveInternalTimer($hash, "KLF200_connectionBroken"); #clear watchdog to check if connection is broken
  readingsBeginUpdate($hash);
	readingsBulkUpdateIfChanged($hash, "connectionBroken", 0, 1);
	readingsEndUpdate($hash, 1);

  my $bytes = KLF200_UnwrapBytes($hash, $buf);
  return if(!defined($bytes));
  
  my $hexString = unpack("H*", $bytes); 
  Log3($name, 5, "KLF200 ($name) - received: $hexString"); 
  
  my $command = substr($bytes, 0, 2);
 	if    ($command eq"\x30\x01") { KLF200_GW_PASSWORD_ENTER_CFM($hash, $bytes); }
 	elsif ($command eq"\x02\x41") { KLF200_GW_HOUSE_STATUS_MONITOR_ENABLE_CFM($hash, $bytes); }
 	elsif ($command eq"\x04\x13") { KLF200_GW_ACTIVATE_SCENE_CFM($hash, $bytes); }
 	elsif ($command eq"\x00\x02") { KLF200_GW_REBOOT_CFM($hash, $bytes); }
 	elsif ($command eq"\x00\x00") { KLF200_GW_ERROR_NTF($hash, $bytes); }
 	elsif ($command eq"\x03\x02") { KLF200_DispatchToNode($hash, $bytes); }
 	elsif ($command eq"\x03\x03") { KLF200_DispatchToNode($hash, $bytes); }
 	elsif ($command eq"\x02\x11") { KLF200_DispatchToNode($hash, $bytes); }
 	elsif ($command eq"\x02\x04") { KLF200_DispatchToNode($hash, $bytes); }
	else	{ Log3($name, 1, "KLF200 ($name) - ignored:  $hexString"); }     
}

# called if set command is executed
sub KLF200_Set($$$@) {
    my ($hash, $name, $cmd, @arg) = @_;
    Log3($name, 5, "KLF200 ($name) - Set $cmd") if ($cmd ne "?");

    if   ($cmd eq "scene") 				{ KLF200_GW_ACTIVATE_SCENE_REQ($hash, $arg[0], 0); }
    elsif($cmd eq "on") 					{ KLF200_GW_ACTIVATE_SCENE_REQ($hash, 13, 2); } #13: Dachboden 100% fast
    elsif($cmd eq "off") 					{ KLF200_GW_ACTIVATE_SCENE_REQ($hash, 18, 0); } #18: Dachboden 0%	default 
    elsif($cmd eq "login") 				{ KLF200_GW_PASSWORD_ENTER_REQ($hash); }
    elsif($cmd eq "updateNodes") 	{ KLF200_GW_GET_ALL_NODES_INFORMATION_REQ($hash); }
    elsif($cmd eq "reboot") 	    { KLF200_GW_REBOOT_REQ($hash); }
    elsif($cmd eq "closeConnection") 	{ DevIo_CloseDev($hash); }
    elsif($cmd eq "openConnection") 	{ KLF200_Ready($hash); }    
    else {
    		my $usage = "unknown argument $cmd, choose one of scene on:noArg off:noArg login:noArg updateNodes:noArg reboot:noArg closeConnection:noArg openConnection:noArg";
        return $usage;
    }
}
    
# will be executed upon successful connection establishment (see DevIo_OpenDev())
sub KLF200_Init($) {
    my ($hash) = @_;

		KLF200_GW_PASSWORD_ENTER_REQ($hash);
    return undef; 
}

# will be executed if connection establishment fails (see DevIo_OpenDev())
sub KLF200_Callback($$) {
	my ($hash, $error) = @_;
	if(defined($error)) {
    my $name = $hash->{NAME};
    Log3($name, 5, "KLF200 ($name) - error while connecting: $error"); 
	}
  return undef; 
}

sub KLF200_WrapBytes($$) {
	my ($hash, $bytes) = @_;
	my $name = $hash->{NAME};
	my $SLIP_END = "\xC0";
	my $SLIP_ESC = "\xDB";
	my $SLIP_ESC_END = "\xDC";
	my $SLIP_ESC_ESC = "\xDD";
	my $ProtocolID = "\x00";

	my $hexString = unpack("H*", $bytes);
	Log3($hash, 5, "KLF200 $name: unwrapped bytes     $hexString");
	
	my $length = pack("C", (length($bytes) + 1) );
	$bytes = $ProtocolID.$length.$bytes;
	
	my $CheckSumNum = 0;
	$CheckSumNum ^= $_ for unpack('C*', $bytes);
	my $CheckSum = pack("C", $CheckSumNum);
	$bytes = $bytes.$CheckSum;
	
	$bytes =~ s/\xDB/\xDB\xDD/g;        #replace SLIP_ESC by SLIP_ESC SLIP_ESC_ESC
	$bytes =~ s/\xC0/\xDB\xDC/g;        #replace SLIP_END by SLIP_ESC SLIP_ESC_END
	$bytes = $SLIP_END.$bytes.$SLIP_END;
	
	$hexString = unpack("H*", $bytes);
	Log3($hash, 5, "KLF200 $name: wrapped bytes $hexString");
	return $bytes;
}

sub KLF200_UnwrapBytes($$) {
	my ($hash, $bytes) = @_;
	my $name = $hash->{NAME};

  my $hexString = unpack("H*", $bytes);	
	if ("\xC0\x00" ne substr($bytes, 0, 2) or
	   ("\xC0" ne substr($bytes, length($bytes) - 1, 1))) {
		Log3($hash, 1, "KLF200 ($name) No SLIP protocol: $hexString");
		return undef;
	}
	$bytes = substr($bytes, 2, length($bytes) - 3); #remove SLIP_END and ProtocolID
	$bytes =~ s/\xDB\xDD/\xDB/g;        #replace SLIP_ESC SLIP_ESC_ESC by SLIP_ESC
	$bytes =~ s/\xDB\xDC/\xC0/g;        #replace SLIP_ESC SLIP_ESC_END by SLIP_END
	
	$bytes = substr($bytes, 0, length($bytes) - 1); #cut CRC
	my $expLength = unpack('C', substr($bytes, 0, 1));
	my $actLength = length($bytes);
	if ($expLength != $actLength ) {
		Log3($hash, 1, "KLF200 ($name) Invalid length: expected $expLength received $actLength bytes, trying to decode anyway");
		Log3($hash, 1, "KLF200 ($name) Invalid length: $hexString");
	}
	$bytes = substr($bytes, 1); #cut length

	return $bytes;
}

sub KLF200_Write($$) {
	my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};

  if ((ReadingsVal($name, "state", "") ne "Logged in") 
    and (substr($bytes, 0, 2) ne "\x30\x00")){
  	Log3 ($name, 1, "KLF200 ($name) Command skipped, not logged in");
  	return;
  }	
	$bytes = KLF200_WrapBytes($hash, $bytes);
	
#	DevIo_SimpleWrite($hash, $bytes, 0);
  my $length = length($bytes);
  my $written = $hash->{TCPDev}->write($bytes);
  if ($written ne $length) {
    $written = "undef" if (not defined($written));
    Log3 ($name, 1, "KLF200 ($name) Error: written $written of $length bytes");
  }

	RemoveInternalTimer($hash);
  InternalTimer( gettimeofday() + 600, "KLF200_GW_GET_STATE_REQ", $hash); #call after 10 minutes to keep alive
  InternalTimer( gettimeofday() + 5, "KLF200_connectionBroken", $hash); #the box answers in 1s, assume after 5s the connection is broken
	return;
}

sub KLF200_DispatchToNode($$) {
	my ($hash, $bytes) = @_;
	my $found = Dispatch($hash, $bytes);
	if (not defined($found)) {
    RemoveInternalTimer($hash, "KLF200_GW_GET_ALL_NODES_INFORMATION_REQ");
    InternalTimer( gettimeofday() + 20, "KLF200_GW_GET_ALL_NODES_INFORMATION_REQ", $hash); #after auto create, update node again in 20 seconds
	};
	return;
}

sub KLF200_getPassword($) {
  my ($hash) = @_;
  my $default = "velux123";
  
  my $pwfile= $hash->{"pwfile"};
  if(open(PWFILE, $pwfile)) {
    my @contents= <PWFILE>;
    close(PWFILE);
    return $default unless @contents;
    my $password = $contents[0];
    chomp $password;
    return $password;
  } else {
    return $default;
  }
}

sub KLF200_getNextSessionID($) {
  my ($hash) = @_;
	my $name = $hash->{NAME};
  my $SessionID = ReadingsVal($name, "sessionID", 0) + 1;
  if ($SessionID > 65535) {$SessionID = 1};
  readingsSingleUpdate($hash, "sessionID", $SessionID, 1);
  return $SessionID;
}

sub KLF200_connectionBroken($) {
  my ($hash) = @_;
	my $name = $hash->{NAME};
	
  if (ReadingsVal($name, "connectionBroken", 0) == 1) { return; };
	
	DevIo_CloseDev($hash);
	Log3($name, 1, "KLF200 ($name) - connectionBroken -> closed connection");
	
  readingsBeginUpdate($hash);
  readingsBulkUpdateIfChanged($hash, "state", "Connection broken", 1);
	readingsBulkUpdateIfChanged($hash, "connectionBroken", 1, 1);
	readingsEndUpdate($hash, 1);
	
	Log3($name, 1, "KLF200 ($name) - connectionBroken -> reopen connection in 5 seconds");
  InternalTimer( gettimeofday() + 5, "KLF200_Ready", $hash); 
  return;
}

sub KLF200_GW_PASSWORD_ENTER_REQ($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	
	my $Command = "\x30\x00";
	my $Password = pack("a32", KLF200_getPassword($hash));
	my $bytes = $Command.$Password;
	Log3($hash, 5, "KLF200 ($name) GW_PASSWORD_ENTER_REQ");
	KLF200_Write($hash, $bytes);
	return;
}

sub KLF200_GW_PASSWORD_ENTER_CFM($$) {
	my ($hash, $bytes) = @_;
	my $name = $hash->{NAME};
	my ($commandHex, $Status) = unpack("H4 C", $bytes);
	Log3($hash, 5, "KLF200 ($name) GW_PASSWORD_ENTER_CFM $commandHex $Status");
	
  if ($Status != 0) {
    readingsSingleUpdate($hash, "state", "Log in failed", 1);
    return;
  }
  my $connectionsAfterBoot = ReadingsVal($name, "connectionsAfterBoot", 0) + 1;
  
  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "connectionsAfterBoot", $connectionsAfterBoot, 1);
  readingsBulkUpdate($hash, "state", "Logged in", 1);
	readingsEndUpdate($hash, 1);
	
  if (($connectionsAfterBoot > 1) and (AttrVal($name, "autoReboot", 1) == 1)) {
  	#After successful login: try to reboot box if this is not the first connection
  	KLF200_GW_REBOOT_REQ($hash);
  	return;
  }
	#After successful login: start status monitor
	KLF200_GW_HOUSE_STATUS_MONITOR_ENABLE_REQ($hash);
	return;
}

sub KLF200_GW_HOUSE_STATUS_MONITOR_ENABLE_REQ($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	
	my $Command = "\x02\x40";

	Log3($hash, 5, "KLF200 ($name) GW_HOUSE_STATUS_MONITOR_ENABLE_REQ");
	KLF200_Write($hash, $Command);
	return;
}

sub KLF200_GW_HOUSE_STATUS_MONITOR_ENABLE_CFM($$) {
	my ($hash, $bytes) = @_;
	my $name = $hash->{NAME};
	my ($commandHex) = unpack("H4", $bytes);
	Log3($hash, 5, "KLF200 ($name) GW_HOUSE_STATUS_MONITOR_ENABLE_CFM $commandHex");
	
	#After starting status monitor: update all nodes
	KLF200_GW_GET_ALL_NODES_INFORMATION_REQ($hash);
	return;
}

sub KLF200_GW_GET_STATE_REQ($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	
	my $Command = "\x00\x0C";
	
	Log3($hash, 5, "KLF200 ($name) GW_GET_STATE_REQ");
	KLF200_Write($hash, $Command);
	return;
}

sub KLF200_GW_GET_ALL_NODES_INFORMATION_REQ($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	
	my $Command = "\x02\x02";
	
	Log3($hash, 5, "KLF200 ($name) GW_GET_ALL_NODES_INFORMATION_REQ");
	KLF200_Write($hash, $Command);
	return;
} 

sub KLF200_GW_ACTIVATE_SCENE_REQ($$$) {
	my ($hash, $SceneID, $Velocity) = @_;
	my $name = $hash->{NAME};
	
	my $Command = "\x04\x12";
	my $SessionID = KLF200_getNextSessionID($hash);
	my $SessionIDShort = pack("n", $SessionID);
	my $CommandOriginator = "\x08"; #SAAC Stand Alone Automatic Controls 
	my $PriorityLevel = "\05"; #Comfort Level 2 Used by Stand Alone Automatic Controls 
	my $SceneIDByte = pack("C", $SceneID);
	my $VelocityByte = pack("C", $Velocity);
	
	my $bytes = $Command.$SessionIDShort.$CommandOriginator.$PriorityLevel.$SceneIDByte.$VelocityByte;
	Log3($hash, 5, "KLF200 ($name) KLF200_GW_ACTIVATE_SCENE_REQ SessionID $SessionID SceneID $SceneID Velocity $Velocity");
	KLF200_Write($hash, $bytes);
	return;
}

sub KLF200_GW_ACTIVATE_SCENE_CFM($$) {
	my ($hash, $bytes) = @_;
	my $name = $hash->{NAME};
	my ($commandHex, $Status, $SessionID) = unpack("H4 C n", $bytes);
	Log3($hash, 5, "KLF200 ($name) GW_ACTIVATE_SCENE_CFM $commandHex $Status, $SessionID");

	my $sceneStatus = "Session ". $SessionID . ": " . KLF200_GetText($hash, "Status", $Status);

  readingsSingleUpdate($hash, "sceneStatus", $sceneStatus, 1);
	return;  
}

sub KLF200_GW_REBOOT_REQ($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	
	my $Command = "\x00\x01";
	
	Log3($hash, 5, "KLF200 ($name) GW_REBOOT_REQ");
	KLF200_Write($hash, $Command);
  readingsSingleUpdate($hash, "state", "Reboot", 1);
	return;
} 

sub KLF200_GW_REBOOT_CFM($$) {
	my ($hash, $bytes) = @_;
	my $name = $hash->{NAME};
	my ($commandHex) = unpack("H4", $bytes);
	Log3($hash, 5, "KLF200 ($name) GW_REBOOT_CFM $commandHex");

  DevIo_CloseDev($hash);	
	InternalTimer( gettimeofday() + 30, "KLF200_Ready", $hash); #Try to reconnect in 30 seconds
  readingsSingleUpdate($hash, "connectionsAfterBoot", 0, 1);
	Log3($name, 1, "KLF200 ($name) - connectionBroken -> reboot started, reconnect in 30 seconds");
	return;  
}

sub KLF200_GW_ERROR_NTF($$) {
	my ($hash, $bytes) = @_;
	my $name = $hash->{NAME};
	my ($commandHex, $ErrorNumber) = unpack("H4 C", $bytes);
	Log3($hash, 5, "KLF200 ($name) GW_ERROR_NTF $commandHex $ErrorNumber");

	my $lastError = KLF200_GetText($hash, "ErrorNumber", $ErrorNumber);

  readingsSingleUpdate($hash, "lastError", $lastError, 1);
	Log3($name, 1, "KLF200 ($name) - Gateway Error: $lastError");
	return;  
}
1;