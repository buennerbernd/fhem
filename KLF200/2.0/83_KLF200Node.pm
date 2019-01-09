##############################################################################
#
# 83_KLF200Node.pm
# Copyright by Stefan Bünnig buennerbernd
#
# $Id: 83_KLF200.pm 2.0.10 2019-01-09 10:10:10Z buennerbernd $
#
##############################################################################

package main;
use strict;
use warnings;
use Encode;

sub KLF200Node_Initialize($) {
  my ($hash) = @_;

  $hash->{DefFn}      = 'KLF200Node_Define';
  $hash->{UndefFn}    = 'KLF200Node_Undef';
  $hash->{SetFn}      = 'KLF200Node_Set';
  $hash->{GetFn}      = 'KLF200Node_Get';
  $hash->{ReadFn}     = 'KLF200Node_Read';
  $hash->{ParseFn}    = 'KLF200Node_Parse';
  
  $hash->{AttrList}   = "directionOn:up,down velocity:DEFAULT,SILENT,FAST " . $readingFnAttributes;
  $hash->{parseParams}  = 1;
  $hash->{Match}      = ".*";

}

sub KLF200Node_Define($$) {
  my ($hash, $def) = @_;
 
  my @param= @{$def};    
  if(int(@param) < 4) {
      return "too few parameters: define <name> KLF200Node <DeviceName> <NodeID>";
  }
    
  my $DeviceName  = $param[2];
  $hash->{DeviceName} = $DeviceName;
  my $NodeID  = $param[3];
  $hash->{NodeID} = $NodeID;
  
  # Map address backwards to $hash (for ParseFn)
  $modules{KLF200Node}{defptr}{$DeviceName}{$NodeID} = $hash;

  KLF200Node_InitTexts($hash);
  
  return undef;
}

sub KLF200Node_InitTexts($) {
  my ($hash) = @_;
   
  $hash->{".Const"}->{OperatingState} = {
    0 => "Non executing",
    1 => "Error while execution",
    2 => "'Not used'",
    3 => "Waiting for power",
    4 => "Executing",
    5 => "Done",
    255 => "State unknown",
  };
  $hash->{".Const"}->{RunStatus} = {
    0 => "EXECUTION COMPLETED",
    1 => "EXECUTION FAILED",
    2 => "EXECUTION ACTIVE",
  };
  $hash->{".Const"}->{StatusReply} = {
    0x00 => "UNKNOWN STATUS REPLY",
    0x01 => "COMMAND COMPLETED OK",
    0x02 => "NO CONTACT",
    0x03 => "MANUALLY OPERATED",
    0x04 => "BLOCKED",
    0x05 => "WRONG SYSTEMKEY",
    0x06 => "PRIORITY LEVEL LOCKED",
    0x07 => "REACHED WRONG POSITION",
    0x08 => "ERROR DURING EXECUTION",
    0x09 => "NO EXECUTION",
    0x0A => "CALIBRATING",
    0x0B => "POWER CONSUMPTION TOO HIGH",
    0x0C => "POWER CONSUMPTION TOO LOW",
    0x0D => "LOCK POSITION OPEN",
    0x0E => "MOTION TIME TOO LONG  COMMUNICATION ENDED",
    0x0F => "THERMAL PROTECTION",
    0x10 => "PRODUCT NOT OPERATIONAL",
    0x11 => "FILTER MAINTENANCE NEEDED",
    0x12 => "BATTERY LEVEL",
    0x13 => "TARGET MODIFIED",
    0x14 => "MODE NOT IMPLEMENTED",
    0x15 => "COMMAND INCOMPATIBLE TO MOVEMENT",
    0x16 => "USER ACTION",
    0x17 => "DEAD BOLT ERROR",
    0x18 => "AUTOMATIC CYCLE ENGAGED",
    0x19 => "WRONG LOAD CONNECTED",
    0x1A => "COLOUR NOT REACHABLE",
    0x1B => "TARGET NOT REACHABLE",
    0x1C => "BAD INDEX RECEIVED",
    0x1D => "COMMAND OVERRULED",
    0x1E => "NODE WAITING FOR POWER",
    0xDF => "INFORMATION CODE",
    0xE0 => "PARAMETER LIMITED",
    0xE1 => "LIMITATION BY LOCAL USER",
    0xE2 => "LIMITATION BY USER",
    0xE3 => "LIMITATION BY RAIN",
    0xE4 => "LIMITATION BY TIMER",
    0xE6 => "LIMITATION BY UPS",
    0xE7 => "LIMITATION BY UNKNOWN DEVICE",
    0xEA => "LIMITATION BY SAAC",
    0xEB => "LIMITATION BY WIND",
    0xEC => "LIMITATION BY MYSELF",
    0xED => "LIMITATION BY AUTOMATIC CYCLE",
    0xEE => "LIMITATION BY EMERGENCY",
  };
  $hash->{".Const"}->{Velocity} = {
    0 => "DEFAULT",
    1 => "SILENT",
    2 => "FAST",
    255 => "VELOCITY NOT AVAILABLE",
  }; 
  $hash->{".Const"}->{NodeTypeSubType} = {
    0x0040 => "Interior Venetian Blind",
    0x0080 => "Roller Shutter",
    0x0081 => "Adjustable slats rolling shutter",
    0x0082 => "Roller Shutter With projection",
    0x00C0 => "Vertical Exterior Awning",
    0x0100 => "Window opener",
    0x0101 => "Window opener with integrated rain sensor",
    0x0140 => "Garage door opener",
    0x017A => "Garage door opener",
    0x0180 => "Light",
    0x01BA => "Light only supporting on/off",
    0x01C0 => "Gate opener",
    0x01FA => "Gate opener",
    0x0200 => "Rolling Door Opener",
    0x0240 => "Door lock",
    0x0241 => "Window lock",
    0x0280 => "Vertical Interior Blinds",
    0x0300 => "Beacon",
    0x0340 => "Dual Roller Shutter",
    0x0380 => "Heating Temperature Interface",
    0x03C0 => "On/Off switch",
    0x0400 => "Horizontal awning",
    0x0440 => "Exterior Venetian blind",
    0x0480 => "Louver blind",
    0x04C0 => "Curtain track",
    0x0500 => "Ventilation point",
    0x0501 => "Air inlet",
    0x0502 => "Air transfer",
    0x0503 => "Air outlet",
    0x0540 => "Exterior heating",
    0x057A => "Exterior heating",
    0x0580 => "Heat pump",
    0x05C0 => "Intrusion alarm",
    0x0600 => "Swinging Shutters",
    0x0601 => "Swinging Shutter with independent handling of the leaves",
  }; 
  $hash->{".Const"}->{NodeVariation} = {
    0 => "NOT SET",
    1 => "TOPHUNG",
    2 => "KIP",
    3 => "FLAT ROOF",
    4 => "SKY LIGHT",
  };
  $hash->{".Const"}->{PowerMode} = {
    0 => "ALWAYS ALIVE",
    1 => "LOW POWER MODE",
  };
  $hash->{".Const"}->{ioManufacturerId} = {
    1 => "VELUX",
    2 => "Somfy",
    3 => "Honeywell",
    4 => "Hörmann",
    5 => "ASSA ABLOY",
    6 => "Niko",
    7 => "WINDOW MASTER",
    8 => "Renson",
    9 => "CIAT",
    10 => "Secuyou",
    11 => "OVERKIZ",
    12 => "Atlantic Group",
  };
  $hash->{".Const"}->{StatusID} = {
    0x01 => "USER",
    0x02 => "RAIN",
    0x03 => "TIMER",
    0x05 => "UPS",
    0x08 => "PROGRAM",
    0x09 => "WIND",
    0x0A => "MYSELF",
    0x0B => "AUTOMATIC_CYCLE",
    0x0C => "EMERGENCY",
    0xFF => "UNKNOWN",
  };
  $hash->{".Const"}->{CommandOriginator} = {
    1 => "USER",
    2 => "RAIN",
    3 => "TIMER",
    5 => "UPS",
    8 => "SAAC",
    9 => "WIND",
    11 => "LOAD_SHEDDING",
    12 => "LOCAL_LIGHT",
    13 => "UNSPECIFIC_ENVIRONMENT_SENSOR",
    255 => "EMERGENCY",
  };
  $hash->{".Const"}->{StatusType} = {
    0 => "Target_position",
    1 => "Current_position",
    2 => "Remaining_time",
    3 => "Main_info",
  };
   
  return;
}

sub KLF200Node_GetText($$$) {
  my ($hash, $const, $id) = @_;
  my $name = $hash->{NAME};
  
  my $text = $hash->{".Const"}->{$const}->{$id};
  if (not defined($text)) {
    Log3($hash, 3, "KLF200 $name: Unknown $const ID: $id");
    return $id
  };
  
  return $text;
}

sub KLF200Node_GetId($$$$) {
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

sub KLF200Node_Undef($$) {
  my ($hash, $arg) = @_; 
  my $NodeID = $hash->{NodeID};
  my $DeviceName = $hash->{DeviceName};
  delete $modules{KLF200Node}{defptr}{$DeviceName}{$NodeID};
  return undef;
}

sub KLF200Node_Get($@) {
  my ($hash, @param) = @_;
    # nothing to do
    return undef;
}

sub KLF200Node_Set($$$) {
  my ($hash, $argsref, undef) = @_;
  my @a= @{$argsref};
  return "set needs at least one parameter" if(@a < 2);
  
  my $name = shift @a;
  my $cmd= shift @a;
  
  if($cmd eq "state") {
    my $value = shift @a;
    my $velocity = shift @a;
    return KLF200Node_SetState($hash, $value, $velocity);
  }
  if($cmd eq "pct") {
    my $value = shift @a;
    my $velocity = shift @a;
    return KLF200Node_SetState($hash, $value, $velocity);
  }
  if ($cmd =~ /^([0-9]+|on|off|up|down|stop)$/) {
    my $velocity = shift @a;
    return KLF200Node_SetState($hash, $cmd, $velocity);
  }
  if($cmd eq "toggle") {
    my $velocity = shift @a;
    my $value;
    if    (ReadingsVal($hash->{NAME}, "operatingState", "") eq "Executing") { $value = "stop" }
    elsif (ReadingsVal($hash->{NAME}, "pct", 0) < 50)                       { $value = 100 }
    else                                                                    { $value = 0 }
    return KLF200Node_SetState($hash, $value, $velocity);
  }
  if ($cmd eq "target") { 
    return KLF200Node_SetState($hash, "target", "DEFAULT");
  }
  if ($cmd eq "statusRequest") {
    my $statusType = shift @a; 
    return KLF200Node_GW_STATUS_REQUEST_REQ($hash, $statusType);
  }
  my $usage= "Unknown argument $cmd, choose one of";
  $usage .= " on:noArg off:noArg toggle:noArg up:noArg down:noArg stop:noArg" ;
  $usage .= " pct:slider,0,1,100" ;
  $usage .= " statusRequest:Main_info,Target_position,Current_position,Remaining_time" ;
#  $usage .= " target:noArg" ;
  return $usage;
}

sub KLF200Node_SetState($$$) {
  my ($hash, $state, $velocity) = @_;
  my $name = $hash->{NAME};
  Log3($name, 5, "KLF200Node ($name) - Set $state");
  my $raw;
  if    ($state eq "stop") { $raw = 0xD200 }
  elsif ($state eq "up")   { $raw = 0x0000 }
  elsif ($state eq "down") { $raw = 0xC800 }
  elsif ($state eq "target") { $raw = 0xD100 }
  elsif ($state eq "on")   { $raw = KLF200Node_PctToRaw($hash, 100) }
  elsif ($state eq "off")  { $raw = KLF200Node_PctToRaw($hash, 0) }
  else                     { $raw = KLF200Node_PctToRaw($hash, $state) }

  return KLF200Node_GW_COMMAND_SEND_REQ($hash, $raw, $velocity); 
}


sub KLF200Node_Parse ($$)
{
  my ( $io_hash, $bytes) = @_;
  my $io_name = $io_hash->{NAME};
  my $hexString = unpack("H*", $bytes); 
  Log3($io_name, 5, "KLF200Node ($io_name) - received: $hexString"); 
  
  my $command = substr($bytes, 0, 2);
  if    ($command eq "\x03\x02") { return KLF200Node_GW_COMMAND_RUN_STATUS_NTF($io_hash, $bytes) }
  elsif ($command eq "\x03\x03") { return KLF200Node_GW_COMMAND_REMAINING_TIME_NTF($io_hash, $bytes) }
  elsif ($command eq "\x02\x11") { return KLF200Node_GW_NODE_STATE_POSITION_CHANGED_NTF($io_hash, $bytes) }
  elsif ($command eq "\x02\x04") { return KLF200Node_GW_GET_ALL_NODES_INFORMATION_NTF($io_hash, $bytes) }
  elsif ($command eq "\x02\x10") { return KLF200Node_GW_GET_ALL_NODES_INFORMATION_NTF($io_hash, $bytes) }
  elsif ($command eq "\x03\x07") { return KLF200Node_GW_STATUS_REQUEST_NTF($io_hash, $bytes) }
  elsif ($command eq "\x01\x02") { return KLF200Node_GW_CS_GET_SYSTEMTABLE_DATA_NTF($io_hash, $bytes) }
  else  { Log3($io_name, 1, "KLF200Node ($io_name) - ignored:  $hexString"); return undef; }
}

sub KLF200Node_RawToPct($$) {
  my ($hash, $raw) = @_; 
  my $name = $hash->{NAME};
  my $pct;
  my $directionOn = AttrVal($name, "directionOn", "up");
  if ($directionOn eq "up") { 
    $pct = int(100.5 - ($raw / 512)); 
  }
  else { 
    $pct = int($raw / 512 + 0.5); 
  }
  return $pct;
}

sub KLF200Node_PctToRaw($$) {
  my ($hash, $pct) = @_; 
  my $name = $hash->{NAME};
  if    ($pct < 0)   {$pct = 0}
  elsif ($pct > 100) {$pct = 100};
  my $raw;
  my $directionOn = AttrVal($name, "directionOn", "up");
  if ($directionOn eq "up") { 
    $raw = int((100 - $pct) * 512); 
  }
  else { 
    $raw = int($pct * 512); 
  }  
  return $raw;
}

sub KLF200Node_BulkUpdateStatePct($$) {
  my ($hash, $raw) = @_; 
  my $name = $hash->{NAME};
  
  my $changed = readingsBulkUpdateIfChanged($hash, "MP", $raw, 1);
  if ($raw > 0xC800) { Log3($hash, 5, "KLF200Node ($name) unsupported position raw $raw, keep last known position"); return; }
  my $pct = KLF200Node_RawToPct($hash, $raw);
  readingsBulkUpdateIfChanged($hash, "pct", $pct, 1);
  my $state;
  if ($pct == 100) { $state = "on" }
  elsif ($pct == 0) { $state = "off" }
  else { $state = $pct }
  readingsBulkUpdateIfChanged($hash, "state", $state, 1);
  return $changed;
}

sub KLF200Node_BulkUpdateTarget($$) {
  my ($hash, $raw) = @_; 
  my $name = $hash->{NAME};
  if ($raw > 0xC800) { Log3($hash, 5, "KLF200Node ($name) unsupported target raw $raw, keep last known target"); return; }
  my $pct = KLF200Node_RawToPct($hash, $raw);
  readingsBulkUpdateIfChanged($hash, "target", $pct, 1);
}

sub KLF200Node_BulkUpdateRemaining($$) {
  my ($hash, $remaining) = @_; 
  my $name = $hash->{NAME};
  readingsBulkUpdateIfChanged($hash, "remaining", $remaining, 1);
  if ($remaining == 0) {
    return undef;
  }
  my $targetArrival = gettimeofday() + $remaining;
  my $targetArrivalStr = FmtDateTime($targetArrival);
  if (defined(readingsBulkUpdateIfChanged($hash, "targetArrival", $targetArrivalStr, 1))) {
    return $targetArrival;
  }
  return undef;
}

sub KLF200Node_BulkUpdateFP($$$) {
  my ($hash, $fp, $raw) = @_; 
  my $name = $hash->{NAME};
  
  my $readingName = "FP".$fp;
  #Don't create useless readings
  readingsBulkUpdate($hash, $readingName, $raw, 1) if (ReadingsVal($name, $readingName, 0xF7FF) != $raw);
}

sub KLF200Node_GetHash($$) {
  my ($io_hash, $NodeID) = @_;
  my $DeviceName = $io_hash->{DeviceName};
  my $hash = $modules{KLF200Node}{defptr}{$DeviceName}{$NodeID};
  if(!defined($hash)) { 
    my $io_name = $io_hash->{NAME};
    my $undefined = "UNDEFINED ".$io_name."_".$NodeID." KLF200Node ".$DeviceName." ".$NodeID; 
    return (undef, $undefined); 
  };
  $hash->{IODev} = $io_hash;
  return ($hash, undef); 
}


sub KLF200Node_GW_COMMAND_RUN_STATUS_NTF($$) {
  my ($io_hash, $bytes) = @_;

  my ($commandHex, $SessionID, $StatusID, $NodeID, $NodeParameter, $ParameterValue, $RunStatus, $StatusReply, $InformationCode) 
    = unpack("H4 n C C C n C C H8", $bytes);

  my ($hash, $undefined) = KLF200Node_GetHash($io_hash, $NodeID);
  if (not defined($hash)) {return $undefined};

  my $name = $hash->{NAME};
  Log3($hash, 5, "KLF200Node ($name) GW_COMMAND_RUN_STATUS_NTF $commandHex $SessionID $StatusID $NodeID FP$NodeParameter:$ParameterValue $RunStatus $StatusReply $InformationCode");
  
  my $SessionStatusOwner = KLF200Node_GetText($hash, "StatusID", $StatusID);
  my $SessionRunStatus = KLF200Node_GetText($hash, "RunStatus", $RunStatus);
  my $SessionStatusReply = KLF200Node_GetText($hash, "StatusReply", $StatusReply);
  my $LastCommandOriginator = 8;
  my $LastCommandOriginatorStr = KLF200Node_GetText($hash, "CommandOriginator", $LastCommandOriginator);
  my $LastMasterExecutionAddress = ReadingsVal($io_hash->{NAME}, "address", "UNKNOWN");
  my $LastControl;
  if ($LastMasterExecutionAddress eq "UNKNOWN") { $LastControl = "FHEM" }
  else { $LastControl = KLF200_getControlName($io_hash, $LastMasterExecutionAddress, $LastCommandOriginator) }
  
  readingsBeginUpdate($hash);
  if ($NodeParameter == 0) { #MP: Main Parameter
    KLF200Node_BulkUpdateStatePct($hash, $ParameterValue);
  }
  else {
    KLF200Node_BulkUpdateFP($hash, $NodeParameter, $ParameterValue);
  }
  readingsBulkUpdateIfChanged($hash, "sessionID", $SessionID, 1);
  readingsBulkUpdateIfChanged($hash, "sessionStatusOwner", $SessionStatusOwner, 1);
  readingsBulkUpdateIfChanged($hash, "sessionRunStatus", $SessionRunStatus, 1);
  readingsBulkUpdateIfChanged($hash, "sessionStatusReply", $SessionStatusReply, 1);
  readingsBulkUpdateIfChanged($hash, "sessionInformationCode", $InformationCode, 1);
  readingsBulkUpdateIfChanged($hash, "lastMasterExecutionAddress", $LastMasterExecutionAddress, 1);
  readingsBulkUpdateIfChanged($hash, "lastControl", $LastControl, 1);
  readingsBulkUpdateIfChanged($hash, "lastCommandOriginator", $LastCommandOriginatorStr, 1);
  if ($RunStatus != 2) {
    KLF200Node_BulkUpdateRemaining($hash, 0);
  }
  readingsEndUpdate($hash, 1);
  
  if (($LastMasterExecutionAddress eq "UNKNOWN") and ($RunStatus != 2)) {
    #determine the address of KLF200
    KLF200Node_GW_STATUS_REQUEST_REQ($hash, "Main_info");
  }
  return $name;
}

sub KLF200Node_GW_COMMAND_REMAINING_TIME_NTF($$) {
  my ($io_hash, $bytes) = @_;

  my ($commandHex, $SessionID, $NodeID, $NodeParameter, $Seconds) 
    = unpack("H4 n C C n", $bytes);
    
  my ($hash, $undefined) = KLF200Node_GetHash($io_hash, $NodeID);
  if (not defined($hash)) {return $undefined};

  my $name = $hash->{NAME};    
  Log3($hash, 5, "KLF200Node ($name) GW_COMMAND_REMAINING_TIME_NTF $commandHex $SessionID $NodeID FP$NodeParameter = $Seconds");
  readingsBeginUpdate($hash);
  if ($NodeParameter == 0) {
    KLF200Node_BulkUpdateRemaining($hash, $Seconds);
  }
  else {
    my $readingName = "FP".$NodeParameter."remaining";
    readingsBulkUpdateIfChanged($hash, $readingName, $Seconds, 1);
  }
  
  readingsEndUpdate($hash, 1);
  return $name;
}

sub KLF200Node_GW_NODE_STATE_POSITION_CHANGED_NTF($$) {
  my ($io_hash, $bytes) = @_;

  my ($commandHex, $NodeID, $State, $CurrentPosition, $Target, 
    $FP1CurrentPosition, $FP2CurrentPosition, $FP3CurrentPosition, $FP4CurrentPosition,
    $RemainingTime, $TimeStamp) 
    = unpack("H4 C C n n n n n n n N", $bytes); #$TimeStamp is buggy in 0.2.0.0.71.0
    
  my ($hash, $undefined) = KLF200Node_GetHash($io_hash, $NodeID);
  if (not defined($hash)) {return $undefined};

  my $name = $hash->{NAME};
  Log3($hash, 5, "KLF200Node ($name) GW_NODE_STATE_POSITION_CHANGED_NTF $commandHex $NodeID $State FP0:$CurrentPosition T:$Target FP1:$FP1CurrentPosition $RemainingTime $TimeStamp");
  my $OperatingState = KLF200Node_GetText($hash, "OperatingState", $State);
  readingsBeginUpdate($hash);
  my $changed = KLF200Node_BulkUpdateStatePct($hash, $CurrentPosition);
  KLF200Node_BulkUpdateTarget($hash, $Target);
  KLF200Node_BulkUpdateFP($hash, 1, $FP1CurrentPosition);
  KLF200Node_BulkUpdateFP($hash, 2, $FP2CurrentPosition);
  KLF200Node_BulkUpdateFP($hash, 3, $FP3CurrentPosition);
  KLF200Node_BulkUpdateFP($hash, 4, $FP4CurrentPosition);
  KLF200Node_BulkUpdateRemaining($hash, $RemainingTime);
  readingsBulkUpdateIfChanged($hash, "operatingState", $OperatingState, 1) if ($OperatingState ne "'Not used'");
  readingsEndUpdate($hash, 1);
  if(defined($changed) and (ReadingsVal($name, "sessionRunStatus", "") ne "EXECUTION ACTIVE")) {
    #Otherwhise it could destroy a running session
    KLF200Node_GW_STATUS_REQUEST_REQ($hash, "Main_info");
  }
  return $name;
}

sub KLF200Node_GW_GET_NODE_INFORMATION_REQ($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};    
  my $Command = "\x02\x00";
  my $NodeId = $hash->{NodeID};
  Log3($hash, 5, "KLF200Node ($name) KLF200Node_GW_GET_NODE_INFORMATION_REQ");

  my $NodeIdByte = pack("C", $NodeId);

  my $bytes = $Command.$NodeIdByte;
  return IOWrite($hash, $bytes);
}

sub KLF200Node_GW_GET_ALL_NODES_INFORMATION_NTF($$) {
  my ($io_hash, $bytes) = @_;
  
  my ($commandHex, $NodeID, $Order, $Placement, $NodeName, $Velocity, 
    $NodeTypeSubType, $ProductGroup, $ProductType, $NodeVariation, $PowerMode, $BuildNumber,
    $Serial1, $Serial2, $Serial3, $Serial4, $Serial5, $Serial6, $State, $CurrentPosition, $Target, 
    $FP1CurrentPosition, $FP2CurrentPosition, $FP3CurrentPosition, $FP4CurrentPosition,
    $RemainingTime, $TimeStamp, $NbrOfAlias, $AliasArray) 
    = unpack("H4 C n C a64 C n C C C C C C n C C C n C n n n n n n n N C H*", $bytes);
  
  my ($hash, $undefined) = KLF200Node_GetHash($io_hash, $NodeID);
  if (not defined($hash)) {return $undefined};
  
  $NodeName =~ s/\x00+$//;
  $NodeName = decode("UTF-8", $NodeName);  
  my $OperatingState = KLF200Node_GetText($hash, "OperatingState", $State);
  my $VelocityStr = KLF200Node_GetText($hash, "Velocity", $Velocity);
  my $NodeVariationStr = KLF200Node_GetText($hash, "NodeVariation", $NodeVariation);
  my $PowerModeStr = KLF200Node_GetText($hash, "PowerMode", $PowerMode);
  my $name = $hash->{NAME};
  my $klf200Time = FmtDateTime($TimeStamp);
  my $Serial = "$Serial1 $Serial2 $Serial3 $Serial4 $Serial5 $Serial6";
  Log3($hash, 5, "KLF200Node ($name) GW_GET_ALL_NODES_INFORMATION_NTF $commandHex $NodeID $NodeName $State FP0:$CurrentPosition T:$Target FP1:$FP1CurrentPosition V:$Velocity $RemainingTime $klf200Time");
  readingsBeginUpdate($hash);
  KLF200Node_BulkUpdateStatePct($hash, $CurrentPosition);
  KLF200Node_BulkUpdateTarget($hash, $Target);
  KLF200Node_BulkUpdateFP($hash, 1, $FP1CurrentPosition);
  KLF200Node_BulkUpdateFP($hash, 2, $FP2CurrentPosition);
  KLF200Node_BulkUpdateFP($hash, 3, $FP3CurrentPosition);
  KLF200Node_BulkUpdateFP($hash, 4, $FP4CurrentPosition);
  KLF200Node_BulkUpdateRemaining($hash, $RemainingTime);
  readingsBulkUpdateIfChanged($hash, "operatingState", $OperatingState, 1) if ($OperatingState ne "State unknown");
  readingsBulkUpdateIfChanged($hash, "velocity", $VelocityStr, 1);
  readingsBulkUpdateIfChanged($hash, "nodeVariation", $NodeVariationStr, 1);
  if (defined(readingsBulkUpdateIfChanged($hash, "name", $NodeName, 1))) {
    $attr{$name}{alias} = $NodeName if ($NodeName ne ""); #only if name has changed and is not empty   
  }
  readingsBulkUpdateIfChanged($hash, "powerMode", $PowerModeStr, 1);
  readingsBulkUpdateIfChanged($hash, "productGroup", $ProductGroup, 1);  
  readingsBulkUpdateIfChanged($hash, "productType", $ProductType, 1);  
  readingsBulkUpdateIfChanged($hash, "buildNumber", $BuildNumber, 1);
  if (defined(readingsBulkUpdateIfChanged($hash, "serial", $Serial, 1))) {
    my $year = 2000 + $Serial4;
    my (undef,undef,undef,undef,undef,$maxYear,undef,undef,undef) = localtime();
    $maxYear += 1900;
    if (($year >= 2005) and ($year <= $maxYear) and ($Serial5 <= 53)) {
      my $production = $year." week ".$Serial5;
      readingsBulkUpdate($hash, "production", $production, 1);
    }
  }
  readingsEndUpdate($hash, 1);
  if ($commandHex eq "0210") {
    KLF200_Dequeue($io_hash, qr/^\x02\x00/, undef);
  }
  return $name;
}

sub KLF200Node_GW_CS_GET_SYSTEMTABLE_DATA_NTF($$) {
  my ($io_hash, $bytes) = @_;
  my $io_name = $io_hash->{NAME};
  
  my ($commandHex, $NumberOfEntry) = unpack("H4 C", $bytes);

  my $result;
  for (my $i = 0; $i < $NumberOfEntry; $i++) {
    my $offset = 3 + $i * 11;
    my $SystemTableObject = substr($bytes, $offset, 11);
    my ($NodeID, $ActuatorAddress, $NodeTypeSubType, $Bits, $ioManufacturerId, $BackboneReferenceNumber) = unpack("C H6 n C C H6", $SystemTableObject);

    if ($NodeID < 200) { #Handle only actuators, ignore beacons
      my ($hash, $undefined) = KLF200Node_GetHash($io_hash, $NodeID);
      if (not defined($hash)) {
        $result = $undefined;
      }
      else {
        my $name = $hash->{NAME};
        my $ioManufacturer = KLF200Node_GetText($hash, "ioManufacturerId", $ioManufacturerId);
        my $NodeTypeSubTypeStr = $hash->{".Const"}->{NodeTypeSubType}->{$NodeTypeSubType};
        my $NodeType = $NodeTypeSubType & 0xFFC0;
        my $SubType = $NodeTypeSubType & 0x3F;
        my $NodeTypeSubTypeNum = $NodeType / 0x40;
        $NodeTypeSubTypeNum .= ".".$SubType if ($SubType != 0);
        if (not defined($NodeTypeSubTypeStr)) { #Match the type only.
          $NodeTypeSubTypeStr = $hash->{".Const"}->{NodeTypeSubType}->{$NodeType}; 
          if (not defined($NodeTypeSubTypeStr)) { $NodeTypeSubTypeStr = $NodeTypeSubTypeNum };
        };
        my $model = $ioManufacturer;
        $model .= " ".$NodeTypeSubTypeStr if ($NodeTypeSubTypeStr ne $NodeTypeSubTypeNum);
        $model .= " Type ".$NodeTypeSubTypeNum;
        readingsBeginUpdate($hash);
        readingsBulkUpdateIfChanged($hash, "ioManufacturer", $ioManufacturer, 1);
        readingsBulkUpdateIfChanged($hash, "nodeTypeSubType", $NodeTypeSubTypeStr, 1);
        readingsBulkUpdateIfChanged($hash, "model", $model, 1);
        readingsBulkUpdateIfChanged($hash, "actuatorAddress", $ActuatorAddress, 1);
        readingsBulkUpdateIfChanged($hash, "backboneReferenceNumber", $BackboneReferenceNumber, 1);
        readingsEndUpdate($hash, 1);
        $result = $name if (not defined($result));
      }
    }
    else {
      Log3($io_hash, 3, "KLF200Node ($io_name) GW_CS_GET_SYSTEMTABLE_DATA_NTF $commandHex ignored $NodeID $ActuatorAddress $NodeTypeSubType $Bits $ioManufacturerId $BackboneReferenceNumber");
    }
  }
  my $offset = 3 + $NumberOfEntry * 11;
  my $RemainingNumberOfEntry = unpack("C", substr($bytes, $offset, 1));
  Log3($io_hash, 5, "KLF200Node ($io_name) GW_CS_GET_SYSTEMTABLE_DATA_NTF $commandHex $NumberOfEntry $RemainingNumberOfEntry");
  if ($RemainingNumberOfEntry == 0) {
    KLF200_Dequeue($io_hash, qr/^\x01\x00/, undef);
  }
  return $result;
}

sub KLF200Node_GW_COMMAND_SEND_REQ($$$) {
  my ($hash, $raw, $velocity) = @_;
  my $name = $hash->{NAME};    
  my $NodeId = $hash->{NodeID};
  my $Command = "\x03\x00";
  my $SessionID = 0;
  my $io_hash = $hash->{IODev};
  if (defined($io_hash)) {$SessionID = KLF200_getNextSessionID($io_hash)};
  Log3($hash, 5, "KLF200Node ($name) KLF200Node_GW_COMMAND_SEND_REQ SessionID $SessionID raw $raw");
  my $SessionIDShort = pack("n", $SessionID);
  my $CommandOriginator = "\x08"; #SAAC Stand Alone Automatic Controls 
  my $PriorityLevel = "\05"; #Comfort Level 2 Used by Stand Alone Automatic Controls 
  my $ParameterActive = "\x00";
  
  if(not defined($velocity)) {
    $velocity = AttrVal($name, "velocity", "DEFAULT");
    $hash->{"VelocitySet"} = $velocity;
  }
  my $FPI1FPI2;
  my $FunctionalParameterValueArray;
  if ($velocity eq "SILENT") {
    $FPI1FPI2 = "\x80\x00";
    $FunctionalParameterValueArray = pack("nnx30", $raw, 0);
  }
  elsif ($velocity eq "FAST") {
    $FPI1FPI2 = "\x80\x00";
    $FunctionalParameterValueArray = pack("nnx30", $raw, 51200);
  }
  else {
    $FPI1FPI2 = "\x00\x00";
    $FunctionalParameterValueArray = pack("nx32", $raw);
  }
  my $IndexArrayCount = pack("C", 1);
  my $IndexArray = pack("Cx19", $NodeId);
  my $PriorityLevelLock = "\x00\x00\x00\x00";

  my $bytes = $Command.$SessionIDShort.$CommandOriginator.$PriorityLevel.$ParameterActive.$FPI1FPI2
    .$FunctionalParameterValueArray.$IndexArrayCount.$IndexArray.$PriorityLevelLock;
  return IOWrite($hash, $bytes);
}

sub KLF200Node_GW_STATUS_REQUEST_REQ($$) {
  my ($hash, $statusType) = @_;
  my $name = $hash->{NAME};    
  my $NodeId = $hash->{NodeID};
  my $Command = "\x03\x05";
  my $StatusTypeId = KLF200Node_GetId($hash, "StatusType", $statusType, 3);
  my $SessionID = 0;
  my $io_hash = $hash->{IODev};
  if (defined($io_hash)) {$SessionID = KLF200_getNextSessionID($io_hash)};
  Log3($hash, 5, "KLF200Node ($name) KLF200Node_GW_STATUS_REQUEST_REQ SessionID $SessionID StatusType $StatusTypeId");
  my $SessionIDShort = pack("n", $SessionID);
  my $IndexArrayCount = pack("C", 1);
  my $IndexArray = pack("Cx19", $NodeId);
  my $StatusTypeByte = pack("C", $StatusTypeId);
  my $FPI1FPI2 = "\x00\x00";
  if ($StatusTypeId != 3) {
    $FPI1FPI2 = "\xFE\x00"; #request FP1 - FP7
  }
  my $bytes = $Command.$SessionIDShort.$IndexArrayCount.$IndexArray.$StatusTypeByte.$FPI1FPI2;
  return IOWrite($hash, $bytes);
}

sub KLF200Node_GW_STATUS_REQUEST_NTF($$) {
  my ($io_hash, $bytes) = @_;

  my ($commandHex, $SessionID, $StatusID, $NodeID, $RunStatus, $StatusReply, $StatusType) 
    = unpack("H4 n C C C C C", $bytes);
    
  my ($hash, $undefined) = KLF200Node_GetHash($io_hash, $NodeID);
  if (not defined($hash)) {return $undefined};

  my $name = $hash->{NAME};
  Log3($hash, 5, "KLF200Node ($name) GW_STATUS_REQUEST_NTF $commandHex $SessionID $StatusID $NodeID $RunStatus $StatusReply $StatusType");

  my $SessionStatusOwner = KLF200Node_GetText($hash, "StatusID", $StatusID);
  my $SessionRunStatus = KLF200Node_GetText($hash, "RunStatus", $RunStatus);
  my $SessionStatusReply = KLF200Node_GetText($hash, "StatusReply", $StatusReply);
  my $targetArrival;
  readingsBeginUpdate($hash);
  readingsBulkUpdateIfChanged($hash, "sessionID", $SessionID, 1);
  readingsBulkUpdateIfChanged($hash, "sessionStatusOwner", $SessionStatusOwner, 1);
  readingsBulkUpdateIfChanged($hash, "sessionRunStatus", $SessionRunStatus, 1);
  readingsBulkUpdateIfChanged($hash, "sessionStatusReply", $SessionStatusReply, 1);
  
  if($StatusType == 3) {
    my ($TargetPosition, $CurrentPosition, $RemainingTime, $LastMasterExecutionAddress, $LastCommandOriginator)
      = unpack("n n n H6x C", substr($bytes, 9));
    
    my $LastCommandOriginatorStr = KLF200Node_GetText($hash, "CommandOriginator", $LastCommandOriginator);
    my $LastControl = KLF200_getControlName($io_hash, $LastMasterExecutionAddress, $LastCommandOriginator);
    KLF200Node_BulkUpdateTarget($hash, $TargetPosition);   
    KLF200Node_BulkUpdateStatePct($hash, $CurrentPosition);  
    $targetArrival = KLF200Node_BulkUpdateRemaining($hash, $RemainingTime);
    readingsBulkUpdateIfChanged($hash, "lastMasterExecutionAddress", $LastMasterExecutionAddress, 1);
    readingsBulkUpdateIfChanged($hash, "lastCommandOriginator", $LastCommandOriginatorStr, 1);
    readingsBulkUpdateIfChanged($hash, "lastControl", $LastControl, 1);
  }
  else {
    my $StatusCount = unpack("C", substr($bytes, 9, 1));
    for (my $i = 0; $i < $StatusCount; $i++) {
      my $offset = 10 + $i * 3;
      my $ParameterData = substr($bytes, $offset, 3);
      my ($NodeParameter, $ParameterValue) = unpack("C n", $ParameterData);
      if($NodeParameter == 0) {
        if   ($StatusType == 0) { KLF200Node_BulkUpdateTarget($hash, $ParameterValue) }
        elsif($StatusType == 1) { KLF200Node_BulkUpdateStatePct($hash, $ParameterValue) }
        elsif($StatusType == 2) { $targetArrival = KLF200Node_BulkUpdateRemaining($hash, $ParameterValue) }
      }
      else {
        KLF200Node_BulkUpdateFP($hash, $NodeParameter, $ParameterValue);
      }
    }
  }
  readingsEndUpdate($hash, 1);
  if(defined($targetArrival)) {
    RemoveInternalTimer($hash, "KLF200Node_GW_STATUS_REQUEST_REQ");
    InternalTimer( $targetArrival, "KLF200Node_GW_STATUS_REQUEST_REQ", $hash, 3);
  }     
  return $name;
}

1;
