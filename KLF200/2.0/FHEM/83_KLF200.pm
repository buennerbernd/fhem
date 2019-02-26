##############################################################################
#
# 83_KLF200.pm
# Copyright by Stefan Bünnig buennerbernd
#
# $Id: 83_KLF200.pm 35280 2019-26-02 22:02:57Z buennerbernd $
#
##############################################################################

package main;

use strict;
use warnings;
use DevIo; # load DevIo.pm if not already loaded
use Encode;

# called upon loading the module KLF200
sub KLF200_Initialize($) {
  my ($hash) = @_;

  $hash->{DefFn}    = "KLF200_Define";
  $hash->{UndefFn}  = "KLF200_Undef";
  $hash->{SetFn}    = "KLF200_Set";
  $hash->{ReadFn}   = "KLF200_Read";
  $hash->{ReadyFn}  = "KLF200_Ready";
  $hash->{WriteFn}  = "KLF200_Write";
  $hash->{AttrList} = "autoReboot:0,1 velocity:DEFAULT,SILENT,FAST controlNames " . $readingFnAttributes;
  
  $hash->{parseParams}  = 1;
  $hash->{Clients} = "KLF200Node.*";
  $hash->{MatchList} = { "1:KLF200Node" => ".*" };
  
}

# called when a new definition is created (by hand or from configuration read on FHEM startup)
sub KLF200_Define($$) {
  my ($hash, $def) = @_;
  my @param= @{$def};    
  if(int(@param) < 3) {
      return "wrong syntax: define <name> KLF200 <host>";
  }
    
  my $name = $param[0];
  # $param[1] is always equals the module name "KLF200"
  
  # first argument is the hostname or IP address of the device (e.g. "192.168.1.120")
  my $host = $param[2]; 
  $hash->{Host} = $host;
  $hash->{DeviceName} = $host.':51200';
  $hash->{SSL} = 1;
  $hash->{TIMEOUT} = 10; #default is 3 
  
  $hash->{".sceneUsage"} = "";
  $hash->{".sceneIDUsage"} = "";
  $hash->{".sceneToID"} = {};
  $hash->{".queue"} = [];
  
  # close connection if maybe open (on definition modify)
  DevIo_CloseDev($hash) if(DevIo_IsOpen($hash));  
  
  # open connection with custom init and error callback function (non-blocking connection establishment)
  DevIo_OpenDev($hash, 0, "KLF200_Init", "KLF200_Callback"); 

  KLF200_InitTexts($hash);
 
  return undef;
}

sub KLF200_InitTexts($) {
  my ($hash) = @_;
   
  $hash->{".Const"}->{ErrorNumber} = {
    0 => "Not further defined error.",
    1 => "Unknown Command or command is not accepted at this state.",
    2 => "ERROR on Frame Structure.",
    7 => "Busy. Try again later.",
    8 => "Bad system table index.",
    12 => "Not authenticated.",
  };
  $hash->{".Const"}->{Status} = {
    0 => "OK - Request accepted",
    1 => "Error - Invalid parameter",
    2 => "Error - Request rejected",
  };
  $hash->{".Const"}->{SubState} = {
    0x00 => "Idle state",
    0x01 => "Performing task in Configuration Service handler",
    0x02 => "Performing Scene Configuration",
    0x03 => "Performing Information Service Configuration",
    0x04 => "Performing Contact input Configuration",
    0x80 => "Performing task in Command Handler",
    0x81 => "Performing task in Activate Group Handler",
    0x82 => "Performing task in Activate Scene Handler",
  };
  $hash->{".Const"}->{Velocity} = {
    0 => "DEFAULT",
    1 => "SILENT",
    2 => "FAST",
    255 => "VELOCITY NOT AVAILABLE",
  }; 
  $hash->{".Const"}->{CommandOriginator} = {
    1 => "User Remote control",
    2 => "Rain sensor",
    3 => "Timer controlled",
    5 => "UPS unit",
    8 => "Stand Alone Automatic Controls",
    9 => "Wind sensor",
    11 => "Electric load shed",
    12 => "Local light sensor",
    13 => "Unknown sensor",
    255 => "Emergency or security commands",
  };
  
}

sub KLF200_GetText($$$) {
  my ($hash, $const, $id) = @_;
  my $name = $hash->{NAME};
  
  my $text = $hash->{".Const"}->{$const}->{$id};
  if (not defined($text)) {
    Log3($hash, 3, "KLF200 $name: Unknown $const ID: $id");
    return $id
  };
  
  return $text;
}

sub KLF200_GetId($$$$) {
  my ($hash, $const, $text, $default) = @_;
  my $name = $hash->{NAME};
  
  if (not defined($text)) {return $default};
  if ($text =~ /^[0-9]+$/) {return $text};

  my $idToText = $hash->{".Const"}->{$const};
  my %textToId = reverse( %$idToText );   
  my $id = $textToId{$text};
  if(not defined($id)) {
    Log3($hash, 3, "KLF200 $name: Unknown $const text: $text");
    return $default
  };
  
  return $id;
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
  if    ($command eq "\x00\x0D") { KLF200_GW_GET_STATE_CFM($hash, $bytes) }
  elsif ($command eq "\x30\x01") { KLF200_GW_PASSWORD_ENTER_CFM($hash, $bytes) }
  elsif ($command eq "\x20\x01") { KLF200_GW_SET_UTC_CFM($hash, $bytes) }
  elsif ($command eq "\x02\x41") { KLF200_GW_HOUSE_STATUS_MONITOR_ENABLE_CFM($hash, $bytes) }
  elsif ($command eq "\x02\x05") { KLF200_GW_GET_ALL_NODES_INFORMATION_FINISHED_NTF($hash, $bytes) }
  elsif ($command eq "\x00\x09") { KLF200_GW_GET_VERSION_CFM($hash, $bytes) }
  elsif ($command eq "\x04\x13") { KLF200_GW_ACTIVATE_SCENE_CFM($hash, $bytes) }
  elsif ($command eq "\x03\x04") { KLF200_GW_SESSION_FINISHED_NTF($hash, $bytes) }
  elsif ($command eq "\x04\x0D") { KLF200_GW_GET_SCENE_LIST_CFM($hash, $bytes) }
  elsif ($command eq "\x04\x0E") { KLF200_GW_GET_SCENE_LIST_NTF($hash, $bytes) }
  elsif ($command eq "\x00\x02") { KLF200_GW_REBOOT_CFM($hash, $bytes) }
  elsif ($command eq "\x00\x00") { KLF200_GW_ERROR_NTF($hash, $bytes) }
  elsif ($command eq "\x03\x01") { KLF200_GW_COMMAND_SEND_CFM($hash, $bytes) }
  elsif ($command eq "\x03\x02") { KLF200_DispatchToNode($hash, $bytes) }
  elsif ($command eq "\x03\x03") { KLF200_DispatchToNode($hash, $bytes) }
  elsif ($command eq "\x03\x07") { KLF200_DispatchToNode($hash, $bytes) }
  elsif ($command eq "\x03\x14") { KLF200_DispatchToNode($hash, $bytes) }
  elsif ($command eq "\x02\x11") { KLF200_DispatchToNode($hash, $bytes) }
  elsif ($command eq "\x02\x04") { KLF200_DispatchToNode($hash, $bytes) }
  elsif ($command eq "\x02\x10") { KLF200_DispatchToNode($hash, $bytes) }
  elsif ($command eq "\x01\x02") { KLF200_DispatchToNode($hash, $bytes) }
  else  { Log3($name, 1, "KLF200 ($name) - ignored:  $hexString") }     
}

# called if set command is executed
sub KLF200_Set($$$) {
  my ($hash, $argsref, undef) = @_;
  my @a= @{$argsref};
  return "set needs at least one parameter" if(@a < 2);
  
  my $name = shift @a;
  my $cmd  = shift @a;
  my $arg1 = shift @a;
  my $arg2 = shift @a;
  
  Log3($name, 5, "KLF200 ($name) - Set $cmd") if ($cmd ne "?");

  if    ($cmd eq "scene")          { KLF200_GW_ACTIVATE_SCENE_REQ($hash, $hash->{".sceneToID"}->{$arg1}, $arg2) }
  elsif ($cmd eq "sceneID")        { KLF200_GW_ACTIVATE_SCENE_REQ($hash, $arg1, $arg2) }
  elsif ($cmd eq "login")          { KLF200_login($hash, $arg1) }
  elsif ($cmd eq "updateNodes")    { KLF200_GW_GET_ALL_NODES_INFORMATION_REQ($hash) }
  elsif ($cmd eq "updateAll")      { KLF200_UpdateAll($hash) }
  elsif ($cmd eq "reboot")         { KLF200_GW_REBOOT_REQ($hash) }
  elsif ($cmd eq "clearLastError") { readingsSingleUpdate($hash, "lastError", "", 1); return undef }   
  else {
      my $sceneUsage = $hash->{".sceneUsage"};
      my $sceneIDUsage = $hash->{".sceneIDUsage"};
      my $usage = "unknown argument $cmd, choose one of scene:$sceneUsage sceneID:$sceneIDUsage login updateNodes:noArg updateAll:noArg reboot:noArg clearLastError:noArg";
      return $usage;
  }
}
    
# will be executed upon successful connection establishment (see DevIo_OpenDev())
sub KLF200_Init($) {
    my ($hash) = @_;

    KLF200_login($hash, undef);
    
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

sub KLF200_Attr($$$$)
{
  my ( $cmd, $name, $attrName, $attrValue  ) = @_;
  
  if ($attrName eq "controlNames") {
    if ($cmd eq "set") {
#Todo
#      my %hash = map{split /\:/, $_}(split /;/, $string);
    }
  }
}

sub KLF200_UpdateAll($) {
    my ($hash) = @_;

    KLF200_GW_GET_SCENE_LIST_REQ($hash);
    KLF200_GW_GET_ALL_NODES_INFORMATION_REQ($hash);
    KLF200_GW_CS_GET_SYSTEMTABLE_DATA_REQ($hash);
    KLF200_GW_GET_VERSION_REQ($hash);
    KLF200_GW_HOUSE_STATUS_MONITOR_ENABLE_REQ($hash);
    return; 
}

sub KLF200_WrapBytes($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};
  my $SLIP_END = "\xC0";
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

  my $queue = $hash->{".queue"};
  push (@$queue, $bytes);
  readingsSingleUpdate($hash, "queueSize", scalar(@$queue), 1);
  if (scalar(@$queue) == 1) {
    KLF200_RunQueue($hash);
  }
}

sub KLF200_WriteDirect($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};

  if (((ReadingsVal($name, "state", "") ne "Logged in") 
    and (substr($bytes, 0, 2) ne "\x30\x00"))
    or not defined($hash->{TCPDev})) {
    Log3 ($name, 1, "KLF200 ($name) Command skipped, not logged in");
    return;
  }  
  $bytes = KLF200_WrapBytes($hash, $bytes);
  
  DevIo_SimpleWrite($hash, $bytes, 0);

  RemoveInternalTimer($hash, "KLF200_GW_GET_STATE_REQ");
  InternalTimer( gettimeofday() + 600, "KLF200_GW_GET_STATE_REQ", $hash); #call after 10 minutes to keep alive
  InternalTimer( gettimeofday() + 5, "KLF200_connectionBroken", $hash); #the box answers in 1s, assume after 5s the connection is broken
  return;
}

sub KLF200_Dequeue($$$) {
  my ($hash, $regex, $SessionID) = @_;
  my $name = $hash->{NAME};
  my $queue = $hash->{".queue"};

  Log3 ($name, 5, "KLF200 ($name) Dequeue: regex = $regex") if (defined($regex));
  Log3 ($name, 5, "KLF200 ($name) Dequeue: SessionID = $SessionID") if (defined($SessionID));
  if (scalar(@$queue) == 0) { return };
  Log3 ($name, 5, "KLF200 ($name) Dequeue: " . unpack("H*", @$queue[0]));
  if (defined($regex) and not (@$queue[0] =~ m/$regex/)) { return };
  if (defined($SessionID) and (pack("n", $SessionID) ne substr(@$queue[0], 2, 2))) { return };
  shift(@$queue);
  Log3 ($name, 5, "KLF200 ($name) Dequeue: mached");
  readingsSingleUpdate($hash, "queueSize", scalar(@$queue), 1);
  KLF200_RunQueue($hash)
}

sub KLF200_RunQueue($) {
  my ($hash) = @_;
  my $queue = $hash->{".queue"};
  
  if (scalar(@$queue) > 0) {
    KLF200_WriteDirect($hash, @$queue[0]);
  }
}

sub KLF200_DispatchToNode($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};
  my $found = Dispatch($hash, $bytes);
  if (not defined($found)) {
    Log3($name, 1, "KLF200 ($name) - new Node found, updateAll"); 
    RemoveInternalTimer($hash, "KLF200_UpdateAll");
    InternalTimer( gettimeofday() + 20, "KLF200_UpdateAll", $hash); #after auto create, update node again in 20 seconds
  };
  return;
}

sub KLF200_login($$) {
  my ($hash,$password) = @_;
  
  if ((not defined($password)) or ($password eq "")) {
    $password = KLF200_ReadPassword($hash);
    if (not defined($password)) {
      readingsSingleUpdate($hash, "state", "Login with password requiered", 1);
      return;
    }
  }
  else {
    KLF200_StorePassword($hash,$password);
  }
  KLF200_GW_PASSWORD_ENTER_REQ($hash,$password);
  return;
}

sub KLF200_StorePassword($$) {
  my ($hash, $password) = @_;
  my $index = $hash->{TYPE}."_".$hash->{Host}."_passwd";
  my $key = getUniqueId().$index;
  my $enc_pwd = "";

  if(eval "use Digest::MD5;1") {
    $key = Digest::MD5::md5_hex(unpack "H*", $key);
    $key .= Digest::MD5::md5_hex($key);
  }
  
  for my $char (split //, $password) {
    my $encode=chop($key);
    $enc_pwd.=sprintf("%.2x",ord($char)^ord($encode));
    $key=$encode.$key;
  }
  
  my $err = setKeyValue($index, $enc_pwd);
  return "error while saving the password - $err" if(defined($err));

  return "password successfully saved";
}

sub KLF200_ReadPassword($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  my $index = $hash->{TYPE}."_".$hash->{Host}."_passwd";
  my $key = getUniqueId().$index;
  
  Log3($name, 5, "KLF200 $name: Read password from file");
  
  my ($err, $password) = getKeyValue($index);

  if ( defined($err) ) {
    Log3($name, 3, "KLF200 $name: unable to read password from file: $err");
    return undef; 
  }
  
  if ( defined($password) ) {
    if ( eval "use Digest::MD5;1" ) {
      $key = Digest::MD5::md5_hex(unpack "H*", $key);
      $key .= Digest::MD5::md5_hex($key);
    }
    my $dec_pwd = '';
    for my $char (map { pack('C', hex($_)) } ($password =~ /(..)/g)) {
      my $decode=chop($key);
      $dec_pwd.=chr(ord($char)^ord($decode));
      $key=$decode.$key;
    }
    return $dec_pwd;
  } else {
    Log3($name, 3, "KLF200 $name: No password in file");
    return undef;
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

sub KLF200_getControlName($$$) {
  my ($hash, $masterExecutionAddress, $commandOriginator) = @_;
  my $name = $hash->{NAME};
  
  my $controlId = $masterExecutionAddress."-".$commandOriginator;
  my $controlNamesAttr = AttrVal($name, "controlNames", "");
  my %controlNames = map{split /\:/, $_}(split /,/, $controlNamesAttr);
  
  my $controlName = $controlNames{$controlId};
  return $controlName if (defined($controlName));
  
  my $klf200Address = ReadingsVal($name, "address", undef);
  if ((not defined($klf200Address)) and ($commandOriginator == 8)) {
    #guess $masterExecutionAddress is klf200Address
    $klf200Address = $masterExecutionAddress;
    readingsSingleUpdate($hash, "address", $klf200Address, 1);
  }
  if ($klf200Address eq $masterExecutionAddress) {
    KLF200_addControlName($hash, $klf200Address."-1", "KLF200 Input");
    KLF200_addControlName($hash, $klf200Address."-8", "FHEM");
    return "FHEM" if ($commandOriginator == 8);
    return "KLF200 Input" if ($commandOriginator == 1);
  }
  $controlName = KLF200_GetText($hash, "CommandOriginator", $commandOriginator);
  #persist only if klf200Address is already known
  KLF200_addControlName($hash, $controlId, $controlName) if (defined($klf200Address));
  return $controlName; 
}

sub KLF200_addControlName($$$) {
  my ($hash, $controlId, $controlName) = @_;
  my $name = $hash->{NAME};
  my $controlNamesAttr = AttrVal($name, "controlNames", "");
  $controlNamesAttr .= "," if ($controlNamesAttr ne "");
  $controlNamesAttr .= $controlId.":".$controlName;
  $attr{$name}{"controlNames"} = $controlNamesAttr;
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

sub KLF200_GW_PASSWORD_ENTER_REQ($$) {
  my ($hash, $passwordStr) = @_;
  my $name = $hash->{NAME};
  
  my $Command = "\x30\x00";
  my $Password = pack("a32", $passwordStr); #UTF-8?
  my $bytes = $Command.$Password;
  Log3($hash, 5, "KLF200 ($name) GW_PASSWORD_ENTER_REQ");
  KLF200_WriteDirect($hash, $bytes);
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
  
  #First run the queue to be responsive
  KLF200_RunQueue($hash);
  if (($connectionsAfterBoot > 1) and (AttrVal($name, "autoReboot", 1) == 1)) {
    #After successful login: try to reboot box if this is not the first connection
    KLF200_GW_REBOOT_REQ($hash);
    return;
  }
  #After successful login: set the time of KLF200 box
  KLF200_GW_SET_UTC_REQ($hash);
  return;
}

sub KLF200_GW_SET_UTC_REQ($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  my $Command = "\x20\x00";
  my $time = time();
  my $utcTimeStamp = pack("N", $time);
  my $bytes = $Command.$utcTimeStamp;
  KLF200_WriteDirect($hash, $bytes);

  Log3($hash, 5, "KLF200 ($name) GW_SET_UTC_REQ ".FmtDateTime($time));
  return;
}

sub KLF200_GW_SET_UTC_CFM($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};
  my ($commandHex) = unpack("H4", $bytes);
  Log3($hash, 5, "KLF200 ($name) GW_SET_UTC_CFM $commandHex");
    
  #After successful login and setting the time: update all system data
  KLF200_UpdateAll($hash);
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

  KLF200_Dequeue($hash, qr/^\x02\x40/, undef); #GW_HOUSE_STATUS_MONITOR_ENABLE_REQ
  return;
}

sub KLF200_GW_GET_STATE_REQ($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  my $Command = "\x00\x0C";
  
  Log3($hash, 5, "KLF200 ($name) GW_GET_STATE_REQ");
  KLF200_WriteDirect($hash, $Command);
  return;
}

sub KLF200_GW_GET_STATE_CFM($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};
  my ($commandHex, $GatewayState, $SubState, $StateData) = unpack("H4 C C n", $bytes);
  Log3($hash, 5, "KLF200 ($name) GW_GET_STATE_CFM $commandHex $GatewayState $SubState $StateData");

  if (($GatewayState) == 2 or ($GatewayState == 1)) {
    my $SubStateStr = KLF200_GetText($hash, "SubState", $SubState);
    readingsSingleUpdate($hash, "subState", $SubStateStr, 1);
    
    #If the box is in idle state and the queue is not empty: run the queue.
    #This should never happen, just to be on the safe side.
    KLF200_RunQueue($hash) if ($SubState == 0x00);
  }  
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
 
sub KLF200_GW_GET_ALL_NODES_INFORMATION_FINISHED_NTF($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};
  my ($commandHex) = unpack("H4", $bytes);
  Log3($hash, 5, "KLF200 ($name) GW_GET_ALL_NODES_INFORMATION_FINISHED_NTF $commandHex");

  KLF200_Dequeue($hash, qr/^\x02\x02/, undef); #GW_GET_ALL_NODES_INFORMATION_REQ
  return;
}

sub KLF200_GW_CS_GET_SYSTEMTABLE_DATA_REQ($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  my $Command = "\x01\x00";
  
  Log3($hash, 5, "KLF200 ($name) GW_CS_GET_SYSTEMTABLE_DATA_REQ");
  KLF200_Write($hash, $Command);
  return;
}

sub KLF200_GW_GET_VERSION_REQ($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  my $Command = "\x00\x08";
  
  Log3($hash, 5, "KLF200 ($name) GW_GET_VERSION_REQ");
  KLF200_Write($hash, $Command);
  return;
}

sub KLF200_GW_GET_VERSION_CFM($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};
  my ($commandHex, $SoftwareVersion1, $SoftwareVersion2, $SoftwareVersion3, $SoftwareVersion4, $SoftwareVersion5, $SoftwareVersion6,
    $HardwareVersion, $ProductGroup, $ProductType) 
    = unpack("H4 C C C C C C C C C", $bytes);
  my $SoftwareVersion = "$SoftwareVersion1.$SoftwareVersion2.$SoftwareVersion3.$SoftwareVersion4.$SoftwareVersion5.$SoftwareVersion6";
  Log3($hash, 5, "KLF200 ($name) GW_GET_VERSION_CFM $commandHex $SoftwareVersion $HardwareVersion");

  readingsBeginUpdate($hash);
  readingsBulkUpdateIfChanged($hash, "softwareVersion", $SoftwareVersion, 1);
  readingsBulkUpdateIfChanged($hash, "hardwareVersion", $HardwareVersion, 1);
  readingsBulkUpdateIfChanged($hash, "model", $SoftwareVersion, 1);
  readingsEndUpdate($hash, 1);
   
  KLF200_Dequeue($hash, qr/^\x00\x08/, undef);
  return;  
}

sub KLF200_GW_GET_SCENE_LIST_REQ($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  my $Command = "\x04\x0C";
  
  Log3($hash, 5, "KLF200 ($name) GW_GET_SCENE_LIST_REQ");
  KLF200_Write($hash, $Command);
  return;
}

sub KLF200_GW_GET_SCENE_LIST_CFM($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};
  my ($commandHex, $TotalNumberOfObjects) = unpack("H4 C", $bytes);
  Log3($hash, 5, "KLF200 ($name) GW_GET_SCENE_LIST_CFM $commandHex $TotalNumberOfObjects");
  
  if (($TotalNumberOfObjects > 0) 
    and ((not defined($hash->{"SCENES"})) or ($hash->{"SCENES"} eq ""))
    and (not defined AttrVal($name, "webCmd", undef))) {
    #Set attribute webCmd the first time we found scenes
    $attr{$name}{webCmd} = "scene";
  } 

  $hash->{".sceneUsage"} = "";
  $hash->{".sceneIDUsage"} = "";
  $hash->{"SCENES"} = "";
  %{$hash->{".sceneToID"}} = ();
  %{$hash->{".idToScene"}} = ();
  
  if ($TotalNumberOfObjects == 0) {
    KLF200_Dequeue($hash, qr/^\x04\x0C/, undef);
  }
  return;  
}

sub KLF200_GW_GET_SCENE_LIST_NTF($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};
  my ($commandHex, $NumberOfObject) = unpack("H4 C", $bytes);
  Log3($hash, 5, "KLF200 ($name) GW_GET_SCENE_LIST_NTF $commandHex $NumberOfObject");
  
  my $sceneUsage = $hash->{".sceneUsage"};
  my $sceneIDUsage = $hash->{".sceneIDUsage"};
  my $scenes = $hash->{"SCENES"};
  for (my $i = 0; $i < $NumberOfObject; $i++) {
    my $offset = 3 + $i * 65;
    my $sceneObject = substr($bytes, $offset, 65);
    my ($SceneID, $SceneName) = unpack("C a64", $sceneObject);

    $SceneName =~ s/\x00+$//;
    $SceneName = decode("UTF-8", $SceneName);

    Log3($hash, 5, "KLF200 ($name) GW_GET_SCENE_LIST_NTF $SceneID $SceneName");
    $hash->{".idToScene"}->{$SceneID}  = $SceneName;
    $hash->{".sceneToID"}->{$SceneName}  = $SceneID;
    
    $sceneIDUsage.= "," if(length($sceneIDUsage) > 0);
    $sceneIDUsage.= $SceneID;
    
    $scenes.= ", " if(length($scenes) > 0);
    $scenes.= $SceneID.":\"".$SceneName."\"";
  }
  $hash->{".sceneIDUsage"} = $sceneIDUsage;
  $hash->{"SCENES"} = $scenes;
  
  my $offset = 3 + $NumberOfObject * 65;
  my $RemainingNumberOfObject = unpack("C", substr($bytes, $offset, 1));
  if ($RemainingNumberOfObject == 0) {
    #Calculate sorted scene usage at the end
    foreach my $SceneName (sort values %{$hash->{".idToScene"}}) {
      my $sceneEscaped = $SceneName;
      $sceneEscaped =~ s/ /#/g;
      $sceneUsage.= "," if(length($sceneUsage) > 0);
      $sceneUsage.= "\"".$sceneEscaped."\"";      
    }
    $hash->{".sceneUsage"} = $sceneUsage;
    Log3($hash, 5, "KLF200 ($name) GW_GET_SCENE_LIST_NTF sceneUsage $sceneUsage");
    KLF200_Dequeue($hash, qr/^\x04\x0C/, undef);
  }
  
  return;  
}

sub KLF200_GW_ACTIVATE_SCENE_REQ($$$) {
  my ($hash, $SceneID, $Velocity) = @_;
  my $name = $hash->{NAME};
  
  if (not defined($SceneID)) {
    Log3($hash, 1, "KLF200 ($name) KLF200_GW_ACTIVATE_SCENE_REQ undefined SceneID");
    return;
  };
  $Velocity = AttrVal($name, "velocity", undef) if(not defined($Velocity));
  my $VelocityId = KLF200_GetId($hash, "Velocity", $Velocity, 0);
  my $Command = "\x04\x12";
  my $SessionID = KLF200_getNextSessionID($hash);
  my $SessionIDShort = pack("n", $SessionID);
  my $CommandOriginator = "\x08"; #SAAC Stand Alone Automatic Controls 
  my $PriorityLevel = "\05"; #Comfort Level 2 Used by Stand Alone Automatic Controls 
  my $SceneIDByte = pack("C", $SceneID);
  my $VelocityByte = pack("C", $VelocityId);
  
  my $bytes = $Command.$SessionIDShort.$CommandOriginator.$PriorityLevel.$SceneIDByte.$VelocityByte;
  Log3($hash, 5, "KLF200 ($name) KLF200_GW_ACTIVATE_SCENE_REQ SessionID $SessionID SceneID $SceneID Velocity $VelocityId");
  KLF200_Write($hash, $bytes);

  my $scene = $hash->{".idToScene"}->{$SceneID};  
  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "sceneID", $SceneID, 1);
  if (not defined($scene)) {
    Log3($hash, 1, "KLF200 ($name) KLF200_GW_ACTIVATE_SCENE_REQ unknown scene name for SceneID $SceneID");
  }
  else {
    readingsBulkUpdate($hash, "scene", "\"".$scene."\"", 1);  
  };
  readingsBulkUpdate($hash, "sceneSessionID", $SessionID, 1);
  readingsEndUpdate($hash, 1);
  return;
}

sub KLF200_GW_ACTIVATE_SCENE_CFM($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};
  my ($commandHex, $Status, $SessionID) = unpack("H4 C n", $bytes);
  Log3($hash, 5, "KLF200 ($name) GW_ACTIVATE_SCENE_CFM $commandHex $Status, $SessionID");

  my $sceneStatus = KLF200_GetText($hash, "Status", $Status);

  readingsSingleUpdate($hash, "sceneStatus", $sceneStatus, 1);
  
  if ($Status != 0) {
    #Dequeue in case of error
    KLF200_Dequeue($hash, qr/^\x04\x12/, $SessionID); #GW_ACTIVATE_SCENE_REQ
  }
  return;  
}

sub KLF200_GW_SESSION_FINISHED_NTF($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};
  my ($commandHex, $SessionID) = unpack("H4 n", $bytes);
  Log3($hash, 5, "KLF200 ($name) GW_SESSION_FINISHED_NTF $commandHex $SessionID");
  
  KLF200_Dequeue($hash, qr/^(\x04\x12|\x03\x05|\x03\x12|\x03\x10)/, $SessionID); #GW_ACTIVATE_SCENE_REQ, GW_STATUS_REQUEST_REQ, GW_GET_LIMITATION_STATUS_REQ, GW_SET_LIMITATION_REQ
  return;  
}

sub KLF200_GW_COMMAND_SEND_CFM($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};
  my ($commandHex, $SessionID, $Status) = unpack("H4 n C", $bytes);
  Log3($hash, 5, "KLF200 ($name) GW_COMMAND_SEND_CFM $commandHex $SessionID $Status");
  
  KLF200_Dequeue($hash, qr/^\x03\x00/, $SessionID); #GW_COMMAND_SEND_REQ
  return;  
}

sub KLF200_GW_REBOOT_REQ($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  my $Command = "\x00\x01";
  
  Log3($hash, 5, "KLF200 ($name) GW_REBOOT_REQ");
  KLF200_Write($hash, $Command);
  return;
} 

sub KLF200_GW_REBOOT_CFM($$) {
  my ($hash, $bytes) = @_;
  my $name = $hash->{NAME};
  my ($commandHex) = unpack("H4", $bytes);
  Log3($hash, 5, "KLF200 ($name) GW_REBOOT_CFM $commandHex");

  DevIo_CloseDev($hash);  
  InternalTimer( gettimeofday() + 30, "KLF200_Ready", $hash); #Try to reconnect in 30 seconds
  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "state", "Reboot", 1);
  readingsBulkUpdate($hash, "connectionsAfterBoot", 0, 1);
  readingsEndUpdate($hash, 1);
  Log3($name, 1, "KLF200 ($name) - connectionBroken -> reboot started, reconnect in 30 seconds");
  
  KLF200_Dequeue($hash, qr/^\x00\x01/, undef); #GW_REBOOT_REQ
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
  if ($lastError ne "Busy. Try again later.") {
    KLF200_Dequeue($hash, qr/.*/, undef); #last request
  }
  return;  
}
1;

=pod
=item device
=item summary control io-homecontrol devices via Velux KLF200
=item summary_DE steuert io-homecontrol-Ger&auml;te mittels Velux KLF200 
=begin html

<a name="KLF200"></a>
<h3>KLF200</h3>
<ul>
  This module supports the Velux KLF200 box to control io-homecontrol actors. The box is able to control up to 200 nodes.
  The KLF200 box must have at least firmware version 2.0.0.71 and must be connected to the local network by LAN.<br>
  If you start with a new KLF200 box, use the KLF WebUI to configure the box first. 
  Peer your devices, set names and define some scenes if you like as documented in the KLF200 manual.<br><br>
  
  <a name="KLF200define"></a>
  <b>Define</b><br><br>
  <ul>
    <code>define &lt;name&gt; KLF200 &lt;host&gt;</code><br><br>

    Defines a KLF200 device. <code>&lt;host&gt;</code> is the IP address or hostname of the KLF200 device connected by LAN.<br><br>

    Example:
    <ul>
      <code>define Velux KLF200 192.168.0.66</code><br>
    </ul>
    
    <br>
    Once your device is defined, you have to enter the password:
    <ul>
      <code>set &lt;name&gt; login &lt;password&gt;</code> See below.<br>
    </ul>
    <br>
    After login the devices will be created by auto create as instances of <a href="#KLF200Node">KLF200Node</a>.<br>
    The device name of the nodes will be <code>&lt;name&gt;_&lt;NodeID&gt;</code>, but the names from the KLF200 Web UI will be set as alias.<br>
  </ul><br>
  
  <a name="KLF200set"></a>
  <b>Set</b><br><br>
  <ul>
    <li>
      <code>set &lt;name&gt; login [&lt;password&gt;]</code><br>
      <br>
      As password use the Wifi password, printed at the bottom of the box.
      If this doesn't work, please try the password of the WebUI of the KLF200.
      The password will be stored obfuscated in the FHEM backend and is optional for further login calls.
      <br><br>
      Examples:
      <ul>
        <code>set Velux login abc123</code><br>
        <code>set Velux login</code><br>
      </ul>
      <br>
    </li>
    <li>
      <code>set &lt;name&gt; scene &lt;scene&gt; [DEFAULT|FAST|SILENT]</code><br>
      <br>
      Runs a recorded scene identified by <code>&lt;scene&gt;</code> which is the scene's name defined in the WebUI of KLF200-box.<br>
      The second optional parameter defines the velocity of the actuators when running a scene.
      If this parameter is missing, the attribute <code>velocity</code> is used, see below.<br>
      Note that while running a scene further commands are queued until the scene is completed.
      <br><br>
      Examples:
      <ul>
        <code>set Velux scene "all shutters down"</code><br>
        <code>set Velux scene Night SILENT</code><br>
      </ul>
      <br>
      Scene names with blanks must be enclosed in double quotes.<br>
      <br>
    </li>
    <li>
      <code>set &lt;name&gt; scene &lt;sceneID&gt; [DEFAULT|FAST|SILENT]</code><br>
      <br>
      Runs a recorded scene identified by <code>&lt;sceneID&gt;</code>. To find the scene's ID see Internals SCENES.<br>
      The second optional parameter defines the velocity of the actuators when running a scene.
      If this parameter is missing, the attribute <code>velocity</code> is used, see below.<br>
      Note that while running a scene further commands are queued until the scene is completed.
      <br><br>
      Examples:
      <ul>
        <code>set Velux sceneID 3</code><br>
        <code>set Velux sceneID 1 FAST</code><br>
      </ul>
      <br>
    </li>
    <li>
      <code>set &lt;name&gt; updateAll</code><br>
      <br>
      Update all data and meta data.<br>
      <br>
    </li>
    <li>
      <code>set &lt;name&gt; reboot</code><br>
      <br>
      Reboot the KLF200 box.<br>
      <br>
    </li>
    <li>
      <code>set &lt;name&gt; clearLastError</code><br>
      <br>
      After you have payed attention to the reading <code>lastError</code>, you can clear it.<br>
    </li>
  </ul><br>
  <a name="KLF200attr"></a>
  <b>Attributes</b><br><br>
  <ul>
    <a name="controlNames"></a>
    <li>controlNames<br>
        A comma-separated list of input device name mappings.<br>
        The format is <code>&lt;6 digit hex address&gt;-&lt;command originator number&gt;:&lt;control name&gt;</code>.<br>
        Please only change the control names, e.g.<br>
        <code>895e97-1:Wandtaster,895e97-8:FHEM,ecedd7-1:Fernbedienung</code><br>
        <br>
    </li>
    <a name="velocity"></a>
    <li>velocity<br>
        Defines the speed of the actuators when running a scene. The optional parameter at the set function has a higher priority.<br>
        Values can be DEFAULT, FAST or SILENT. The default value is DEFAULT.<br>
        Note that older actuators don't support setting velocity.<br>
        <br>
    </li>
    <a name="autoReboot"></a>
    <li>autoReboot<br>
        Values can be 0 for off and 1 for on, default is on.<br>
        Reboot the KLF200 box if connection was lost. Reason: The KLF200 box supports only two TCP sockets.
        If the connection was broken a socket is unusable in most cases. So a reboot ensures that always a second socket is available.<br>
        <br>
    </li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br><br>


</ul>

=end html
=cut
