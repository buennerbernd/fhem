##############################################################################
#
# 83_KLF200Node.pm
# Copyright by Stefan Bünnig buennerbernd
#
# $Id: 83_KLF200Node.pm 57347 2022-21-06 06:47:59Z buennerbernd $
#
##############################################################################

package main;
use strict;
use warnings;
use SetExtensions;

sub KLF200Node_Initialize($) {
  my ($hash) = @_;

  $hash->{DefFn}      = 'KLF200Node_Define';
  $hash->{UndefFn}    = 'KLF200Node_Undef';
  $hash->{SetFn}      = 'KLF200Node_Set';
  $hash->{GetFn}      = 'KLF200Node_Get';
  $hash->{ReadFn}     = 'KLF200Node_Read';
  $hash->{ParseFn}    = 'KLF200Node_Parse';
  
  $hash->{AttrList}   = "directionOn:up,down velocity:DEFAULT,SILENT,FAST priorityLevel:5,3,2 " . $readingFnAttributes;
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
  $hash->{".Const"}->{VelocitySupport} = {
    0 => "Supported",
    1 => "Not supported",
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
  $hash->{".Const"}->{ProductCode}->{1}->{0x0080} = {
    1 => "SML",
    5 => "SSL",
  };
  $hash->{".Const"}->{ProductCode}->{1}->{0x00C0} = {
    3 => "MML",
    6 => "MSL",
  };
  $hash->{".Const"}->{ProductCode}->{1}->{0x0101} = {
    1 => "KMG",
    2 => "KMG",
    3 => "CVP",
    7 => "KSX",
    12 => "GPU",
  };
  $hash->{".Const"}->{ProductCode}->{1}->{0x0280} = {
    5 => "FSK",
    6 => "DML",
    7 => "RSL",
  };
  $hash->{".Const"}->{ProductCode}->{1}->{0x0340} = {
    4 => "SMG",
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
  my ($hash, $argsref, $namedParams) = @_;
  my @a= @{$argsref};
  return "set needs at least one parameter" if(@a < 2);
  
  my $name = shift @a;
  my $cmd= shift @a;
  
  if($cmd =~ /^(state|pct|execution)$/) {
    my $value = shift @a;
    my $velocity = shift @a;
    return KLF200Node_SetState($hash, $value, $velocity);
  }
  if ($cmd =~ /^([0-9]+|on|off|up|down|stop|my|securedVentilation)$/) {
    my $velocity = shift @a;
    return KLF200Node_SetState($hash, $cmd, $velocity);
  }
  if($cmd eq "toggle") {
    my $velocity = shift @a;
    return KLF200Node_SetState($hash, KLF200Node_ToggleCmd($hash), $velocity);
  }
  if ($cmd eq "target") { 
    return KLF200Node_SetState($hash, "target", "DEFAULT");
  }
  if ($cmd eq "raw") {
    return KLF200Node_SetRaw($hash, $namedParams);
  }
  if ($cmd eq "statusRequest") {
    my $statusType = shift @a; 
    return KLF200Node_GW_STATUS_REQUEST_REQ($hash, $statusType);
  }
  if ($cmd eq "updateStatus") {
    return KLF200Node_UpdateStatus($hash);
  }
  if ($cmd eq "statusUpdateInterval") {
    my $interval = shift @a; 
    return KLF200Node_SetStatusUpdateInterval($hash, $interval);
  }
  if ($cmd eq "updateCurrentPosition") {
    return KLF200Node_UpdateCurrentPosition($hash);
  }
  if ($cmd eq "updateLimitation") {
    return KLF200Node_UpdateLimitation($hash, "onChange");
  }
  if ($cmd eq "limitationClear") {
    return KLF200Node_SetLimitation($hash, undef, undef);
  }
  if ($cmd eq "limitationMin") {
    my $minPct = shift @a;
    my $test = shift @a;
    if (defined($test) and ($test eq "test")) {
      readingsSingleUpdate($hash, "limitationMin", $minPct, 1);
      return undef;
    } 
    return KLF200Node_SetLimitation($hash, $minPct, undef);
  }
  if ($cmd eq "limitationMax") {
    my $maxPct = shift @a; 
    my $test = shift @a; 
    if (defined($test) and ($test eq "test")) {
      readingsSingleUpdate($hash, "limitationMax", $maxPct, 1);
      return undef;
    } 
    return KLF200Node_SetLimitation($hash, undef, $maxPct);
  }
  if ($cmd eq "limitationUpdateInterval") {
    my $interval = shift @a; 
    return KLF200Node_SetLimitationUpdateInterval($hash, $interval);
  }
  
  my $usage= " on:noArg off:noArg toggle:noArg up:noArg down:noArg stop:noArg" ;
  $usage .= " my:noArg" if (ReadingsVal($name, "ioManufacturer", "") eq "Somfy");
  $usage .= " securedVentilation:noArg" if (ReadingsVal($name, "nodeTypeSubType", "") =~ /^Window opener/ );
  $usage .= " pct:slider,0,1,100" ;
  $usage .= " execution:up,down,stop" ;
  $usage .= " raw" ;
#  $usage .= " statusRequest:Main_info,Target_position,Current_position,Remaining_time" ;
  $usage .= " updateStatus:noArg" ;
  $usage .= " statusUpdateInterval" ;  
  $usage .= " updateCurrentPosition:noArg" ;
  $usage .= " updateLimitation:noArg" ;
  $usage .= " limitationClear:noArg" ;
  $usage .= " limitationMin:slider,0,1,100" ;
  $usage .= " limitationMax:slider,0,1,100" ;  
  $usage .= " limitationUpdateInterval" ;  
#  $usage .= " target:noArg" ;

  return SetExtensions($hash, $usage, $name, $cmd, @a);
}

sub KLF200Node_UpdateLimitation($;$) {
  my ($hash, $limitationUpdateInterval) = @_;
  my $name = $hash->{NAME};
  
  RemoveInternalTimer($hash, "KLF200Node_UpdateLimitation");
  $limitationUpdateInterval = ReadingsVal($name, "limitationUpdateInterval", "off") if (not defined($limitationUpdateInterval));
  if ($limitationUpdateInterval eq "off") { return undef };
  if (ReadingsVal($name, "execution", "stop") ne "stop") {
    #defer if executing
    Log3($name, 5, "KLF200Node ($name) - UpdateLimitation defer");
    $hash->{".UpdateLimitation"} = "YES";
    return undef;
  }
  delete($hash->{".UpdateLimitation"});
  my $result = KLF200Node_GW_GET_LIMITATION_STATUS_REQ($hash, 0);
  KLF200Node_GW_GET_LIMITATION_STATUS_REQ($hash, 1);
  
  InternalTimer( gettimeofday() + $limitationUpdateInterval, "KLF200Node_UpdateLimitation", $hash) if ($limitationUpdateInterval =~ /^\d+$/);
  return $result;
}

sub KLF200Node_UpdateStatus($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  return KLF200Node_GW_STATUS_REQUEST_REQ($hash, "Main_info");
}

sub KLF200Node_UpdateCurrentPosition($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  return KLF200Node_GW_STATUS_REQUEST_REQ($hash, "Current_position");
}

sub KLF200Node_SetState($$$) {
  my ($hash, $state, $velocity) = @_;
  my $name = $hash->{NAME};
  Log3($name, 5, "KLF200Node ($name) - set $state");
  my $MP;
  if    ($state eq "stop")               { $MP = 0xD200 }
  elsif ($state eq "up")                 { $MP = 0x0000 }
  elsif ($state eq "down")               { $MP = 0xC800 }
  elsif ($state eq "target")             { $MP = 0xD100 }
  elsif ($state eq "my")                 { $MP = 0xD800 }
  elsif ($state eq "securedVentilation") { $MP = 0xD803 }
  elsif ($state eq "on")                 { $MP = KLF200Node_PctToRaw($hash, 100) }
  elsif ($state eq "off")                { $MP = KLF200Node_PctToRaw($hash, 0) }
  else                                   { $MP = KLF200Node_PctToRaw($hash, $state) }

  if(not defined($velocity)) { $velocity = AttrVal($name, "velocity", "DEFAULT") }
  $hash->{"VelocitySet"} = $velocity;
  
  my $FP1 = 0xD400;
  if    ($velocity eq "SILENT") { $FP1 = 0x0000 }
  elsif ($velocity eq "FAST")   { $FP1 = 0xC800 }
  
  my @a = ($MP, $FP1);
  return KLF200Node_GW_COMMAND_SEND_REQ($hash, 0, \@a); 
}

sub KLF200Node_SetRaw($$) {
  my ($hash, $namedParams) = @_;
  my $name = $hash->{NAME};
  
  my $ParameterActive = $namedParams->{ParameterActive};
  $ParameterActive = 0 if (not defined($ParameterActive)); 
  my $paramValue = $namedParams->{MP};
  my @a = ($paramValue);
  for my $i (1..16) {
    my $paramName = "FP".$i;
    $paramValue = $namedParams->{$paramName};
    push(@a, $paramValue);
  }
  return KLF200Node_GW_COMMAND_SEND_REQ($hash, $ParameterActive, \@a); 
}

sub KLF200Node_SetLimitation($$$) {
  my ($hash, $minPct, $maxPct) = @_;
  my $name = $hash->{NAME};
  
  if (not defined($minPct) and not defined($maxPct)) {    
    Log3($name, 5, "KLF200Node ($name) - set limitationClear");
    readingsSingleUpdate($hash, ".limitationMin", 0, 1);
    return KLF200Node_GW_SET_LIMITATION_REQ($hash, 0xD400, 0xD400, 255); # 255 = clear all 
  }
  my $pctCurrent = ReadingsVal($name, "pct", 0);
  my $pctNew = undef;
  my $minRaw = ReadingsVal($name, ".limitationMin", 0); #ignore doesn't work for min, use last .limitationMin set
  my $maxRaw = 0xD400; #ignore
  my $directionOn = AttrVal($name, "directionOn", "up");
  if (defined($minPct)) {
    Log3($name, 5, "KLF200Node ($name) - set limitationMin $minPct");
    if($minPct > ReadingsVal($name, "limitationMax", 100)) {
      Log3($name, 1, "KLF200Node ($name) - limitationMin > limitationMax");
      return "limitationMin > limitationMax";
    }
    if($pctCurrent < $minPct) { $pctNew = $minPct };
    if ($directionOn eq "up") {
      $maxRaw = KLF200Node_PctToRaw($hash, $minPct);
    }
    else {
      $minRaw = KLF200Node_PctToRaw($hash, $minPct);
      readingsSingleUpdate($hash, ".limitationMin", $minRaw, 1);
    }
  }
  if (defined($maxPct)) {
    Log3($name, 5, "KLF200Node ($name) - set limitationMax $maxPct");
    if($maxPct < ReadingsVal($name, "limitationMin", 0)) {
      Log3($name, 1, "KLF200Node ($name) - limitationMax < limitationMin");
      return "limitationMax < limitationMin";
    }
    if($pctCurrent > $maxPct) { $pctNew = $maxPct };
    if ($directionOn eq "up") {
      $minRaw = KLF200Node_PctToRaw($hash, $maxPct);
      readingsSingleUpdate($hash, ".limitationMin", $minRaw, 1);
    }
    else {
      $maxRaw = KLF200Node_PctToRaw($hash, $maxPct);
    }
  }
  my $result =  KLF200Node_GW_SET_LIMITATION_REQ($hash, $minRaw, $maxRaw, 253); # 253 = unlimited
  if (defined($pctNew)) { KLF200Node_SetState($hash, $pctNew, undef) };
  return $result;
}

sub KLF200Node_SetLimitationUpdateInterval($$) {
  my ($hash, $interval) = @_;
  my $name = $hash->{NAME};
  
  Log3($name, 5, "KLF200Node ($name) - set limitationUpdateInterval $interval");
  if (not defined($interval) or (not $interval =~ /^(off|onChange|\d+)$/)) {$interval = "off"};
  readingsSingleUpdate($hash, "limitationUpdateInterval", $interval, 1);
  KLF200Node_UpdateLimitation($hash);
}

sub KLF200Node_SetStatusUpdateInterval($$) {
  my ($hash, $interval) = @_;
  my $name = $hash->{NAME};
  
  Log3($name, 5, "KLF200Node ($name) - set statusUpdateInterval $interval");
  if (not defined($interval) or (not $interval =~ /^(default|\d+)$/)) {$interval = "default"};
  readingsSingleUpdate($hash, "statusUpdateInterval", $interval, 1);
  KLF200Node_UpdateStatus($hash);
}

sub KLF200Node_ToggleCmd($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  my $value;
  if (ReadingsVal($hash->{NAME}, "execution", "stop") eq "stop") {
    my $mid = (ReadingsVal($hash->{NAME}, "limitationMin", 0) + ReadingsVal($hash->{NAME}, "limitationMax", 100)) / 2;
    if (ReadingsVal($hash->{NAME}, "pct", 0) < $mid) { $value = 100 }
    else { $value = 0 }
  }
  else { $value = "stop" }
  return $value;
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
  elsif ($command eq "\x03\x14") { return KLF200Node_GW_LIMITATION_STATUS_NTF($io_hash, $bytes) }
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

sub KLF200Node_BulkUpdateMain($$$$$) {
  my ($hash, $rawMP, $rawTarget, $remaining, $state) = @_;
  my $name = $hash->{NAME};
  my $OperatingState = KLF200Node_GetText($hash, "OperatingState", $state);
  if ($OperatingState eq $state) { #Unknown state
    $state = $state & 0x07; #keep last 3 bits and try again
    $OperatingState = KLF200Node_GetText($hash, "OperatingState", $state);
  }
  Log3($hash, 5, "KLF200Node ($name) BulkUpdateMain MP:$rawMP T:$rawTarget R:$remaining $OperatingState");
  my $changed = KLF200Node_BulkUpdateStatePct($hash, $rawMP);
  KLF200Node_BulkUpdateTarget($hash, $rawTarget);
  KLF200Node_BulkUpdateExecution($hash, $rawMP, $rawTarget, $OperatingState);
  my $targetArrival = KLF200Node_BulkUpdateRemaining($hash, $remaining, $OperatingState);
  if (($OperatingState ne "State unknown") and ($OperatingState ne "'Not used'")) {
    readingsBulkUpdateIfChanged($hash, "operatingState", $OperatingState, 1);
  }
  return ($changed, $targetArrival); 
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
  readingsBulkUpdateIfChanged($hash, "MPtarget", $raw, 1);
  if ($raw > 0xC800) { Log3($hash, 5, "KLF200Node ($name) unsupported target raw $raw, keep last known target"); return; }
  my $pct = KLF200Node_RawToPct($hash, $raw);
  readingsBulkUpdateIfChanged($hash, "target", $pct, 1);
}

sub KLF200Node_BulkUpdateExecution($$$$) {
  my ($hash, $rawMP, $rawTarget, $OperatingState) = @_; 
  my $name = $hash->{NAME};
  my $execution = "stop";
  if (($OperatingState eq "Executing") or ($OperatingState eq "'Not used'")) {
    if    (($rawTarget < $rawMP) and ($rawMP <= 51200))     {$execution = "up"}
    elsif (($rawMP < $rawTarget) and ($rawTarget <= 51200)) {$execution = "down"}
  }
  readingsBulkUpdateIfChanged($hash, "execution", $execution, 1);
}

sub KLF200Node_BulkUpdateRemaining($$$) {
  my ($hash, $remaining, $OperatingState) = @_; 
  readingsBulkUpdateIfChanged($hash, "remaining", $remaining, 1);
  if ($remaining == 0) {
    return undef;
  }
  if ($OperatingState eq "Executing") {
    my $targetArrival = gettimeofday() + $remaining;
    my $targetArrivalStr = FmtDateTime($targetArrival);
    if (defined(readingsBulkUpdateIfChanged($hash, "targetArrival", $targetArrivalStr, 1))) {
      return $targetArrival;
    }
  }
  return undef;
}

sub KLF200Node_BulkUpdateFP($$$) {
  my ($hash, $fp, $raw) = @_; 
  my $name = $hash->{NAME};
  if ( $raw != 0xF7FF) {
    #Don't create useless readings
    my $readingName = "FP".$fp;
    Log3($hash, 5, "KLF200Node ($name) BulkUpdate $readingName:$raw");
    readingsBulkUpdateIfChanged($hash, $readingName, $raw, 1) ;
  }
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

sub KLF200Node_getNextSessionID($) {
  my ($hash) = @_;
  my $SessionID = 0;
  my $io_hash = $hash->{IODev};
  $SessionID = KLF200_getNextSessionID($io_hash) if (defined($io_hash));
  return $SessionID;
}

sub KLF200Node_GW_COMMAND_RUN_STATUS_NTF($$) {
  my ($io_hash, $bytes) = @_;

  my ($commandHex, $SessionID, $StatusID, $NodeID, $NodeParameter, $ParameterValue, $RunStatus, $StatusReply, $InformationCode) 
    = unpack("H4 n C C C n C C H8", $bytes);

  my ($hash, $undefined) = KLF200Node_GetHash($io_hash, $NodeID);
  if (not defined($hash)) {return $undefined};

  my $name = $hash->{NAME};
  Log3($hash, 5, "KLF200Node ($name) GW_COMMAND_RUN_STATUS_NTF $commandHex $SessionID $StatusID $NodeID FP$NodeParameter:$ParameterValue $RunStatus $StatusReply $InformationCode");
  if ($StatusID != 8) {
    Log3($hash, 5, "KLF200Node ($name) GW_COMMAND_RUN_STATUS_NTF skipped, not triggered by FHEM");
    return $name;
  }
  my $SessionStatusOwner = KLF200Node_GetText($hash, "StatusID", $StatusID);
  my $LastRunStatus = KLF200Node_GetText($hash, "RunStatus", $RunStatus);
  my $LastStatusReply = KLF200Node_GetText($hash, "StatusReply", $StatusReply);
  my $LastCommandOriginator = 8;
  my $LastCommandOriginatorStr = KLF200Node_GetText($hash, "CommandOriginator", $LastCommandOriginator);
  my $LastMasterExecutionAddress = ReadingsVal($io_hash->{NAME}, "address", "UNKNOWN");
  my $LastControl;
  if ($LastMasterExecutionAddress eq "UNKNOWN") { $LastControl = "FHEM" }
  else { $LastControl = KLF200_getControlName($io_hash, $LastMasterExecutionAddress, $LastCommandOriginator) }
  
  readingsBeginUpdate($hash);
  if ($NodeParameter == 0) { #MP: Main Parameter
    # This Parameter is sometimes buggy, next GW_NODE_STATE_POSITION_CHANGED_NTF has better values
    # Info to KLF200Node_GW_NODE_STATE_POSITION_CHANGED_NTF: GW_STATUS_REQUEST_REQ isn't necessary
    # exept the operatingState is Done, then no direct GW_NODE_STATE_POSITION_CHANGED_NTF will follow
    $hash->{".UpdateStatus"} = "NO" if ( ReadingsVal($name, "operatingState", "Done") ne "Done");
    $hash->{".UpdateStatus"} = "YES" if ($StatusReply == 0x07); #"REACHED WRONG POSITION" workaround for IZYMO
    $hash->{".UpdateStatus"} = "YES" if ($StatusReply == 0x0E); #"MOTION TIME TOO LONG  COMMUNICATION ENDED"
  }
  else {
    KLF200Node_BulkUpdateFP($hash, $NodeParameter, $ParameterValue);
  }
  readingsBulkUpdateIfChanged($hash, "sessionID", $SessionID, 1);
  readingsBulkUpdateIfChanged($hash, "sessionStatusOwner", $SessionStatusOwner, 1);
  readingsBulkUpdateIfChanged($hash, "sessionInformationCode", $InformationCode, 1);
  readingsBulkUpdateIfChanged($hash, "lastRunStatus", $LastRunStatus, 1);
  readingsBulkUpdateIfChanged($hash, "lastStatusReply", $LastStatusReply, 1);
  readingsBulkUpdateIfChanged($hash, "lastMasterExecutionAddress", $LastMasterExecutionAddress, 1);
  readingsBulkUpdateIfChanged($hash, "lastControl", $LastControl, 1);
  readingsBulkUpdateIfChanged($hash, "lastCommandOriginator", $LastCommandOriginatorStr, 1);
  readingsEndUpdate($hash, 1);
  
  if (($LastMasterExecutionAddress eq "UNKNOWN") and ($RunStatus != 2)) {
    #determine the address of KLF200
    KLF200Node_UpdateStatus($hash);
  }
  if (($StatusReply >= 0xE0) and ($StatusReply <= 0xEE)) {
    KLF200Node_UpdateLimitation($hash);
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
    readingsBulkUpdateIfChanged($hash, "remaining", $Seconds, 1);
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
  Log3($hash, 5, "KLF200Node ($name) GW_NODE_STATE_POSITION_CHANGED_NTF $commandHex $NodeID $State MP:$CurrentPosition T:$Target FP1:$FP1CurrentPosition $RemainingTime $TimeStamp");

  RemoveInternalTimer($hash, "KLF200Node_UpdateStatus");
  readingsBeginUpdate($hash);
  my ($changed, $targetArrival) = KLF200Node_BulkUpdateMain($hash, $CurrentPosition, $Target, $RemainingTime, $State);
  KLF200Node_BulkUpdateFP($hash, 1, $FP1CurrentPosition);
  KLF200Node_BulkUpdateFP($hash, 2, $FP2CurrentPosition);
#  KLF200Node_BulkUpdateFP($hash, 3, $FP3CurrentPosition); #For Somfy Exterior Venetian blind Type 17 this only returns buggy results
  KLF200Node_BulkUpdateFP($hash, 4, $FP4CurrentPosition);
  readingsEndUpdate($hash, 1);
  my $statusUpdateInterval = ReadingsVal($name, "statusUpdateInterval", "default");
  if ((ReadingsVal($name, "lastRunStatus", "") ne "EXECUTION ACTIVE")) {
    #Otherwhise it could destroy a running session
    my $updateLimitation = delete($hash->{".UpdateLimitation"});
    my $updateStatus = delete($hash->{".UpdateStatus"});
    if(defined($changed) or defined($targetArrival) or (defined($updateStatus) and ($updateStatus eq "YES"))) {
      $updateStatus = "YES" if (not defined($updateStatus));
      $updateStatus = "YES" if (($updateStatus eq "IF EXECUTING") and ( ReadingsVal($name, "operatingState", "Done") eq "Executing" ) );
      Log3($hash, 5, "KLF200Node ($name) GW_NODE_STATE_POSITION_CHANGED_NTF updateStatus $updateStatus");
      if ($updateStatus eq "YES") {
        $statusUpdateInterval = "default";
        if(defined($targetArrival)) {
          Log3($hash, 5, "KLF200Node ($name) GW_NODE_STATE_POSITION_CHANGED_NTF targetArrival $targetArrival");
          InternalTimer( $targetArrival, "KLF200Node_UpdateStatus", $hash);
        }
        else {     
          KLF200Node_UpdateStatus($hash);
        }
      }
    }
    if ($statusUpdateInterval =~ /^\d+$/) {
      InternalTimer( gettimeofday() + $statusUpdateInterval, "KLF200Node_UpdateStatus", $hash);
    }
    if (defined($updateLimitation) or defined($changed)) {
      KLF200Node_UpdateLimitation($hash);  
    }
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

  my $VelocityStr = KLF200Node_GetText($hash, "VelocitySupport", $Velocity);
  my $NodeVariationStr = KLF200Node_GetText($hash, "NodeVariation", $NodeVariation);
  my $PowerModeStr = KLF200Node_GetText($hash, "PowerMode", $PowerMode);
  my $name = $hash->{NAME};
  my $klf200Time = FmtDateTime($TimeStamp);
  my $Serial = "$Serial1 $Serial2 $Serial3 $Serial4 $Serial5 $Serial6";
  Log3($hash, 5, "KLF200Node ($name) GW_GET_ALL_NODES_INFORMATION_NTF $commandHex $NodeID $NodeName $State MP:$CurrentPosition T:$Target FP1:$FP1CurrentPosition V:$Velocity $RemainingTime $klf200Time");
  readingsBeginUpdate($hash);
  KLF200Node_BulkUpdateMain($hash, $CurrentPosition, $Target, $RemainingTime, $State);
  KLF200Node_BulkUpdateFP($hash, 1, $FP1CurrentPosition);
  KLF200Node_BulkUpdateFP($hash, 2, $FP2CurrentPosition);
  KLF200Node_BulkUpdateFP($hash, 3, $FP3CurrentPosition);
  KLF200Node_BulkUpdateFP($hash, 4, $FP4CurrentPosition);
  readingsBulkUpdateIfChanged($hash, "velocity", $VelocityStr, 1);
  readingsBulkUpdateIfChanged($hash, "nodeVariation", $NodeVariationStr, 1);
  if (defined(readingsBulkUpdateIfChanged($hash, "name", $NodeName, 1))) {
    $attr{$name}{alias} = $NodeName if ($NodeName ne ""); #only if name has changed and is not empty   
  }
  readingsBulkUpdateIfChanged($hash, "powerMode", $PowerModeStr, 1);
  readingsBulkUpdateIfChanged($hash, "productGroup", $ProductGroup, 1) if ($ProductGroup > 0);  
  readingsBulkUpdateIfChanged($hash, "productType", $ProductType, 1) if ($ProductType > 0);  
  readingsBulkUpdateIfChanged($hash, "buildNumber", $BuildNumber, 1) if ($BuildNumber > 0);
  if (($Serial ne "0 0 0 0 0 0") and defined(readingsBulkUpdateIfChanged($hash, "serial", $Serial, 1))) {
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
  KLF200Node_UpdateLimitation($hash);
  return $name;
}

sub KLF200Node_GW_CS_GET_SYSTEMTABLE_DATA_NTF($$) {
  my ($io_hash, $bytes) = @_;
  my $io_name = $io_hash->{NAME};
  
  my ($commandHex, $NumberOfEntry) = unpack("H4 C", $bytes);

  my $result = ""; # No auto create needed
  for (my $i = 0; $i < $NumberOfEntry; $i++) {
    my $offset = 3 + $i * 11;
    my $SystemTableObject = substr($bytes, $offset, 11);
    my ($NodeID, $ActuatorAddress, $NodeTypeSubType, $Bits, $ioManufacturerId, $BackboneReferenceNumber) = unpack("C H6 n C C H6", $SystemTableObject);

    if ($NodeID < 200) { #Handle only actuators, ignore beacons
      my ($hash, $undefined) = KLF200Node_GetHash($io_hash, $NodeID);
      if (not defined($hash)) {
        $result = $undefined; # auto create needed
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
        my $productType = ReadingsVal($name, "productType", 0);
        my $productCode = $hash->{".Const"}->{ProductCode}->{$ioManufacturerId}->{$NodeTypeSubType}->{$productType};
        my $model = $ioManufacturer;
        $model .= " ".$productCode if (defined($productCode));
        $model .= " ".$NodeTypeSubTypeStr if ($NodeTypeSubTypeStr ne $NodeTypeSubTypeNum);
        if (not defined($productCode)) {
          $model .= " Type ".$NodeTypeSubTypeNum;
          if ($productType > 0) {
            $model .= "-".$productType;
            $productCode = "Please report your device";
          }
        }
        readingsBeginUpdate($hash);
        readingsBulkUpdateIfChanged($hash, "ioManufacturer", $ioManufacturer, 1);
        readingsBulkUpdateIfChanged($hash, "nodeTypeSubType", $NodeTypeSubTypeStr, 1);
        readingsBulkUpdateIfChanged($hash, "model", $model, 1);
        readingsBulkUpdateIfChanged($hash, "productCode", $productCode, 1) if (defined($productCode));
        readingsBulkUpdateIfChanged($hash, "actuatorAddress", $ActuatorAddress, 1);
        readingsBulkUpdateIfChanged($hash, "backboneReferenceNumber", $BackboneReferenceNumber, 1);
        if (($NodeTypeSubType == 0x0101) and not defined(ReadingsVal($name, "limitationUpdateInterval", undef))) {
          readingsBulkUpdate($hash, "limitationUpdateInterval", "onChange", 1); #Default value for rain sensor
        }
        readingsEndUpdate($hash, 1);
        $result = $name if ($result eq ""); # Keep previous information (could be auto create)
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
  my ($hash, $ParameterActive, $argsref) = @_;
  my @a= @{$argsref};
  my $name = $hash->{NAME};    
  my $NodeId = $hash->{NodeID};
  my $Command = "\x03\x00";
  my $SessionID = KLF200Node_getNextSessionID($hash);
  my $SessionIDShort = pack("n", $SessionID);
  my $CommandOriginator = "\x08"; #SAAC Stand Alone Automatic Controls
  my $PriorityLevel = pack("C", AttrVal($name, "priorityLevel", 5)); #Default = 5 = Comfort Level 2 Used by Stand Alone Automatic Controls 
  my $ParameterActiveByte = pack("C", $ParameterActive);
  
  my $FPI1FPI2 = 0;
  my $FunctionalParameterValueArray = "";
  my $parametersLog = "";
  for my $i (0..16) { 
    my $ParameterValue = shift @a;
    if (not defined($ParameterValue)) {$ParameterValue = 0xD400}; #IGNORE
    if ($ParameterValue != 0xD400) {
      $FPI1FPI2 = $FPI1FPI2 | (0x10000 >> $i) if ($i > 0);
      $parametersLog .= "FP$i:$ParameterValue "; 
    }    
    my $ParameterValueShort = pack("n", $ParameterValue);
    $FunctionalParameterValueArray .= $ParameterValueShort;
  }
  Log3($hash, 5, "KLF200Node ($name) KLF200Node_GW_COMMAND_SEND_REQ SessionID $SessionID ParameterActive $ParameterActive $parametersLog");
  my $FPI1FPI2Short = pack("n", $FPI1FPI2);
  my $IndexArrayCount = pack("C", 1);
  my $IndexArray = pack("Cx19", $NodeId);
  my $PriorityLevelLock = "\x00\x00\x00\x00";

  my $bytes = $Command.$SessionIDShort.$CommandOriginator.$PriorityLevel.$ParameterActiveByte.$FPI1FPI2Short
    .$FunctionalParameterValueArray.$IndexArrayCount.$IndexArray.$PriorityLevelLock;
  return IOWrite($hash, $bytes);
}


sub KLF200Node_GW_STATUS_REQUEST_REQ($$) {
  my ($hash, $statusType) = @_;
  my $name = $hash->{NAME};    
  my $NodeId = $hash->{NodeID};
  my $Command = "\x03\x05";
  my $StatusTypeId = KLF200Node_GetId($hash, "StatusType", $statusType, 3);
  my $SessionID = KLF200Node_getNextSessionID($hash);
  Log3($hash, 5, "KLF200Node ($name) KLF200Node_GW_STATUS_REQUEST_REQ SessionID $SessionID StatusType $StatusTypeId");
  my $SessionIDShort = pack("n", $SessionID);
  my $IndexArrayCount = pack("C", 1);
  my $IndexArray = pack("Cx19", $NodeId);
  my $StatusTypeByte = pack("C", $StatusTypeId);
  my $FPI1FPI2 = 0x0000;
  if ($StatusTypeId != 3) {
      $FPI1FPI2 = 0xFFFF;
      my $flags = 16;
      my $i = 16;
      #Only 7 FP flags are allowed, remove 9
      while ( $flags > 7 and $i > 0 ) {
        if( not defined(ReadingsVal($name, "FP".$i, undef)) ) {
          $FPI1FPI2 = $FPI1FPI2 ^ (0x10000 >> $i);
          $flags--;
        }
        $i--;
      }
  }
  my $FPI1FPI2Short = pack("n", $FPI1FPI2);
  my $bytes = $Command.$SessionIDShort.$IndexArrayCount.$IndexArray.$StatusTypeByte.$FPI1FPI2Short;
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
  my $LastRunStatus = KLF200Node_GetText($hash, "RunStatus", $RunStatus);
  my $LastStatusReply = KLF200Node_GetText($hash, "StatusReply", $StatusReply);
  readingsBeginUpdate($hash);
  readingsBulkUpdateIfChanged($hash, "sessionID", $SessionID, 1);
  readingsBulkUpdateIfChanged($hash, "sessionStatusOwner", $SessionStatusOwner, 1);
  readingsBulkUpdateIfChanged($hash, "lastRunStatus", $LastRunStatus, 1);
  my $statusReplyChanged = readingsBulkUpdateIfChanged($hash, "lastStatusReply", $LastStatusReply, 1);
  
  if($StatusType == 3) {
    my ($TargetPosition, $CurrentPosition, $RemainingTime, $LastMasterExecutionAddress, $LastCommandOriginator)
      = unpack("n n n H6x C", substr($bytes, 9));
    
    #Do not set main info, next GW_NODE_STATE_POSITION_CHANGED_NTF has better values
    my $LastCommandOriginatorStr = KLF200Node_GetText($hash, "CommandOriginator", $LastCommandOriginator);
    my $LastControl = KLF200_getControlName($io_hash, $LastMasterExecutionAddress, $LastCommandOriginator);
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
        elsif($StatusType == 2) { readingsBulkUpdateIfChanged($hash, "remaining", $ParameterValue, 1) }
      }
      else {
        KLF200Node_BulkUpdateFP($hash, $NodeParameter, $ParameterValue);
      }
    }
  }
  readingsEndUpdate($hash, 1);
  # Info to KLF200Node_GW_NODE_STATE_POSITION_CHANGED_NTF: GW_STATUS_REQUEST_REQ only if currently executing 
  $hash->{".UpdateStatus"} = "IF EXECUTING";
  if (defined($statusReplyChanged) and ($StatusReply >= 0xE0) and ($StatusReply <= 0xEE)) {
    $hash->{".UpdateLimitation"} = "YES";
  }
  return $name;
}

sub KLF200Node_GW_GET_LIMITATION_STATUS_REQ($$) {
  my ($hash, $limitationType) = @_;
  my $name = $hash->{NAME};    
  my $NodeId = $hash->{NodeID};
  my $Command = "\x03\x12";
  my $SessionID = KLF200Node_getNextSessionID($hash);
  Log3($hash, 5, "KLF200Node ($name) KLF200Node_GW_GET_LIMITATION_STATUS_REQ SessionID $SessionID LimitationType $limitationType");
  my $SessionIDShort = pack("n", $SessionID);
  my $IndexArrayCount = pack("C", 1);
  my $IndexArray = pack("Cx19", $NodeId);
  my $NodeParameter = "\x00";
  my $LimitationTypeByte = pack("C", $limitationType);
  
  my $bytes = $Command.$SessionIDShort.$IndexArrayCount.$IndexArray.$NodeParameter.$LimitationTypeByte;
  return IOWrite($hash, $bytes);
}

sub KLF200Node_GW_LIMITATION_STATUS_NTF($$) {
  my ($io_hash, $bytes) = @_;

  my ($commandHex, $SessionID, $NodeID, $ParameterID, $MinValue, $MaxValue, $LimitationOriginator, $LimitationTime) 
    = unpack("H4 n C C n n C C", $bytes);
    
  my ($hash, $undefined) = KLF200Node_GetHash($io_hash, $NodeID);
  if (not defined($hash)) {return $undefined};

  my $name = $hash->{NAME};
  Log3($hash, 5, "KLF200Node ($name) GW_LIMITATION_STATUS_NTF $commandHex $SessionID $NodeID FP$ParameterID min:$MinValue max:$MaxValue $LimitationOriginator $LimitationTime");
  my $directionOn = AttrVal($name, "directionOn", "up");
  my $limitationMin;
  my $limitationMax;
  readingsBeginUpdate($hash);
  if ($MinValue<=0xC800) {
    my $pct = KLF200Node_RawToPct($hash, $MinValue);
    if ($directionOn eq "up") { if (defined(readingsBulkUpdateIfChanged($hash, "limitationMax", $pct, 1))) {$limitationMax = $pct}}
    else                      { if (defined(readingsBulkUpdateIfChanged($hash, "limitationMin", $pct, 1))) {$limitationMin = $pct}}    
  }
  if ($MaxValue<=0xC800) {
    my $pct = KLF200Node_RawToPct($hash, $MaxValue);
    if ($directionOn eq "up") { if (defined(readingsBulkUpdateIfChanged($hash, "limitationMin", $pct, 1))) {$limitationMin = $pct}}
    else                      { if (defined(readingsBulkUpdateIfChanged($hash, "limitationMax", $pct, 1))) {$limitationMax = $pct}}    
  }
  readingsEndUpdate($hash, 1);
  
  if ($LimitationOriginator != 8) {
    my $pct = ReadingsVal($name, "pct", 50);
    if ((defined($limitationMin) and ($pct < $limitationMin))
      or (defined($limitationMax) and ($pct > $limitationMax))) {
      KLF200Node_UpdateStatus($hash);  
    }
  }
  return $name;
}

sub KLF200Node_GW_SET_LIMITATION_REQ($$$$) {
  my ($hash, $valueMin, $valueMax, $limitationTime) = @_;
  my $name = $hash->{NAME};    
  my $NodeId = $hash->{NodeID};
  my $Command = "\x03\x10";
  my $SessionID = KLF200Node_getNextSessionID($hash);
  Log3($hash, 5, "KLF200Node ($name) KLF200Node_GW_SET_LIMITATION_REQ SessionID $SessionID min:$valueMin max:$valueMax $limitationTime");
  my $SessionIDShort = pack("n", $SessionID);
  my $CommandOriginator = "\x08"; #SAAC Stand Alone Automatic Controls 
  my $PriorityLevel = pack("C", AttrVal($name, "priorityLevel", 5)); #Default = 5 = Comfort Level 2 Used by Stand Alone Automatic Controls 
  my $IndexArrayCount = pack("C", 1);
  my $IndexArray = pack("Cx19", $NodeId);
  my $ParameterID = "\x00";
  my $ValueMinShort = pack("n", $valueMin);
  my $ValueMaxShort = pack("n", $valueMax);
  my $LimitationTimeByte = pack("C", $limitationTime);
  
  my $bytes = $Command.$SessionIDShort.$CommandOriginator.$PriorityLevel.$IndexArrayCount.$IndexArray.$ParameterID.$ValueMinShort.$ValueMaxShort.$LimitationTimeByte;
  return IOWrite($hash, $bytes);
}

1;

=pod
=item device
=item summary    represents an io-homecontrol device connected to a Velux KLF200 box
=item summary_DE Repr&auml;sentiert ein io-homecontrol Ger&auml;t an einer Velux KLF200 Box
=begin html

<a name="KLF200Node"></a>
<h3>KLF200Node</h3>
<ul>
  The module KLF200Node represents an io-homecontrol device connected to a Velux KLF200 box.<br><br>
  
  <a name="KLF200Nodedefine"></a>    
  <b>Define</b><br><br>
  <ul>
    Devices of this module will be created by auto create by module <a href="#KLF200">KLF200</a>.<br>
    The default name of the devices follow the pattern <code>&lt;KLF200 device name&gt;_&lt;NodeID&gt;</code>.
    Devices can be renamed. If the device has a name in the KLF200 WebUI. This name is set as alias by default.
  </ul><br>
  <a name="KLF200Nodereadings"></a>
  <b>Readings</b><br><br>
  <ul>
    <li>pct<br>
        The current known position in percent.<br>
        See command <code>set pct</code> below.
    </li>
    <li>target<br>
        The target position in percent.<br>
    </li>
    <li>execution<br>
        The current execution state. Values can be <code>up</code> or <code>down</code> while executing
        and <code>stop</code> otherwhise.<br>
        See command <code>set execution</code> below.
    </li>
    <li>remaining<br>
        The remaining time in sec. until the node arrives the target.
        This value is what the device is reporting.
        Note that the value could be &gt; 0 even if the device is not moving,
        e.g. when the target is not arrived because of an error. See also reading targetArrival.<br>
    </li>
    <li>targetArrival<br>
        The expected point in time when the node arrives the target.
        This reading is calculated via reading remaining, but only if the device is really moving.<br>
    </li>
    <li>operatingState<br>
        The operating state of the node.<br>
    </li>
    <li>lastRunStatus<br>
        The status of the current or last command.<br>
    </li>
    <li>lastStatusReply<br>
        An additional message to the status of the current or last command, e.g. reason for failure.<br>
    </li>
    <li>lastMasterExecutionAddress<br>
        Address of the last control device.
    </li>
    <li>lastCommandOriginator<br>
        Classification of the last control, e.g. USER, RAIN, SAAC (Stand Alone Automatic Controls).<br>
    </li>
    <li>lastControl<br>
        Name of the last control device. This can be changed in <a href="#KLF200attr">KLF200 attribute controlNames</a><br>
    </li>
    <li>limitationMin<br>
        The minimum allowed state. Moving below this value is blocked. This could be set by sensors or FHEM.
    </li>    
    <li>limitationMax<br>
        The maximum allowed state. Moving beyond this value is blocked. This could be set by sensors or FHEM.
    </li>    
    <li>limitationMax<br>
        The maximum allowed state. Moving beyond this value is blocked. This could be set by sensors or FHEM.
    </li>    
    <li>limitationUpdateInterval<br>
        Defines how often to poll the values of limitationMin and limitationMax from the device.<br>
        See command <code>set limitationUpdateInterval</code> below.
    </li>    
  </ul><br>
  <a name="KLF200Nodeset"></a>
  <b>Set</b><br><br>
  <ul>
    <li>
      <code>set &lt;name&gt; &lt;up|down|stop&gt; [DEFAULT|FAST|SILENT]</code><br>
      <br>
      Like <code>set &lt;name&gt; execution &lt;up|down|stop&gt; [DEFAULT|FAST|SILENT]</code><br>
      Do the same as usual io-homecontrol remote controls with button up, down and stop.<br>
      The second optional parameter defines the velocity of the actuator for this command.
      If this parameter is missing, the attribute <code>velocity</code> is used, see below.<br>
      <br>
      Examples:
      <ul>
        <code>set Velux_1 up</code><br>
        <code>set Velux_2 down SILENT</code><br>
        <code>set Velux_3 stop</code><br>
      </ul>
      <br>
    </li>
    <li>
      <code>set &lt;name&gt; &lt;on|off&gt; [DEFAULT|FAST|SILENT]</code><br>
      <br>
      By default <code>on</code> is mapped to <code>up</code> and <code>off</code> to <code>down</code>.<br>
      This can be changed by attribute <code>directionOn</code><br>
      The second optional parameter defines the velocity of the actuator for this command.
      If this parameter is missing, the attribute <code>velocity</code> is used, see below.<br>
      <br>
    </li>
    <a name="pct"></a>
    <li>
      <code>set &lt;name&gt; pct &lt;0 - 100&gt; [DEFAULT|FAST|SILENT]</code><br>
      <br>
      By default <code>100</code> is mapped to <code>up</code> and <code>0</code> to <code>down</code>.<br>
      This can be changed by attribute <code>directionOn</code><br>
      The second optional parameter defines the velocity of the actuator for this command.
      If this parameter is missing, the attribute <code>velocity</code> is used, see below.<br>
      <br>
      Examples:
      <ul>
        <code>set Velux_1 pct 100</code><br>
        <code>set Velux_2 pct 33.333 FAST</code><br>
      </ul>
      <br>
    </li>
    <a name="execution"></a>
    <li>
      <code>set &lt;name&gt; execution &lt;up|down|stop&gt; [DEFAULT|FAST|SILENT]</code><br>
      <br>
      Do the same as usual io-homecontrol remote controls with button up, down and stop.<br>
      The second optional parameter defines the velocity of the actuator for this command.
      If this parameter is missing, the attribute <code>velocity</code> is used, see below.<br>
      <br>
      Examples:
      <ul>
        <code>set Velux_1 execution up</code><br>
        <code>set Velux_2 execution down SILENT</code><br>
        <code>set Velux_3 execution stop</code><br>
      </ul>
      <br>
    </li>
    <a name="toggle"></a>
    <li>
      <code>set &lt;name&gt; toggle [DEFAULT|FAST|SILENT]</code><br>
      <br>
      Stop the node if it is Executing.<br>
      If pct < 50 set pct 100<br>
      If pct >= 50 set pct 0<br>
      <br>
    </li>
    <a name="raw"></a>
    <li>
      <code>set &lt;name&gt; raw [ParameterActive=&lt;0 - 16&gt;] [MP=&lt;0 - 65535&gt;] [FP1=&lt;0 - 65535&gt;] .. [FP16=&lt;0 - 65535&gt;]</code><br>
      <br>
      This setter provides low level access to GW_COMMAND_SEND_REQ of the KLF 200 API.<br>
      It allows to set and combine the Main Parameter (MP) and Functional Parameter #1 (FP1) to Functional Parameter #16 (FP16)
      in the original value range.<br>
      Furthermore it allows to select the ParameterActive to get feedback for this parameter.<br>
      For more details please have a look at the <a href="https://velcdn.azureedge.net/~/media/com/api/klf200/technical%20specification%20for%20klf%20200%20api-ver3-16.pdf">KLF 200 API</a>
      chapters:<br>
      <ul>
        10.1.1 GW_COMMAND_SEND_REQ<br>
        10.1.1.4 ParameterActive parameter<br>
        13 Appendix 1: Standard Parameter definition<br>
        14 Appendix 2: List of actuator types and their use of Main Parameter and Functional Parameters<br>
      </ul>
      <br>
      Examples:
      <ul>
        <code>set Velux_1 raw MP=51200</code><br>
        <code>set Velux_2 raw MP=0 FP1=51200</code><br>
        <code>set Velux_3 raw ParameterActive=3 FP3=25600 FP2=51200</code><br>
      </ul>
    </li>
    <a name="limitationMin"></a>
    <li>
      <code>set &lt;name&gt; limitationMin &lt;0 - 100&gt;</code><br>
      <br>
      Set the minimum allowed state. Moving below this value is blocked.<br>
      If pct &lt; limitationMin the state of the device will be aligned.<br>
      <br>
    </li>
    <a name="limitationMax"></a>
    <li>
      <code>set &lt;name&gt; limitationMax &lt;0 - 100&gt;</code><br>
      <br>
      Set the maximum allowed state. Moving beyond this value is blocked.<br>
      If pct &gt; limitationMax the state of the device will be aligned.<br>
      <br>
    </li>
    <a name="limitationClear"></a>
    <li>
      <code>set &lt;name&gt; limitationClear</code><br>
      <br>
      Clear all limitations at this device, also limitations that may set by other controlers.<br>
      <br>
    </li>
    <a name="limitationUpdateInterval"></a>
    <li>
      <code>set &lt;name&gt; limitationUpdateInterval off|onChange|&lt;s&gt;</code><br>
      <br>
      Defines how often to poll the values of limitationMin and limitationMax from the device.<br>
      off: If the device doesn't have an integrated sensor nor you have any other controler besides from FHEM
      that modifies the limitation, off is the best value.<br>
      onChange: If the device has an integrated sensor, but it is good enough to update
      when the device state has changed, onChange is the best value.<br>
      interval in s: If the device has an integrated sensor and you always want to know how the sensor
      has modified the limitation, define an update interval. 
      Proposal: 600, not below 120.<br>
      Default is off.
      <br>
      Examples:
      <ul>
        <code>set Velux_1 limitationUpdateInterval 600</code><br>
        <code>set Velux_2 limitationUpdateInterval off</code><br>
        <code>set Velux_3 limitationUpdateInterval onChange</code><br>
      </ul>
    </li>
    <a name="updateLimitation"></a>
    <li>
      <code>set &lt;name&gt; updateLimitation</code><br>
      <br>
      Refresh the readings limitationMin and limitationMax from the device.<br>
      <br>
    </li>
    <a name="updateStatus"></a>
    <li>
      <code>set &lt;name&gt; updateStatus</code><br>
      <br>
      Refresh the status readings and the Main Parameter (MP) from the device.<br>
      <br>
    </li>
    <a name="statusUpdateInterval"></a>
    <li>
      <code>set &lt;name&gt; statusUpdateInterval default|&lt;s&gt;</code><br>
      <br>
      Defines how often to update the status from the device.<br>
      default: By default the KLF 200 box decides how often the status of a device is pushed to FHEM depending on the node type.
      If the device was moved by the KLF 200 box then FHEM gets the feedback immediately.
      If the device mas moved by an external remote control then FHEM gets the feedback in a few minutes (in general less than 15 minutes).<br>
      interval in s: If the default behavior is not good enough for you, define an update interval.
      This means if the default behavior waits longer than the interval then an update is forced by poll.
      Proposal: 600, not below 120.<br>
      Default is default.
      <br>
      Examples:
      <ul>
        <code>set Velux_1 statusUpdateInterval 600</code><br>
        <code>set Velux_2 statusUpdateInterval default</code><br>
      </ul>
    </li>
    <a name="updateCurrentPosition"></a>
    <li>
      <code>set &lt;name&gt; updateCurrentPosition</code><br>
      <br>
      Refresh the value of the Main Parameter (MP) and the used Functional Parameters (FP1 - FP7) from the device.<br>
      If you are not using the Functional Parameters (FP1 - FP7) prefer set updateStatus.
      <br>
    </li>
  </ul><br>
  <a name="KLF200Nodeattr"></a>
  <b>Attributes</b><br><br>
  <ul>
    <a name="velocity"></a>
    <li>velocity<br>
        Defines the speed of the actuators when running a command. The optional parameter at the set command has a higher priority.<br>
        Values can be DEFAULT, FAST or SILENT. The default value is DEFAULT.<br>
        Note that older actuators don't support setting velocity.<br>
        This setting is not used for scenes. See <a href="#KLF200attr">KLF200 attribute velocity</a><br>
        <br>
    </li>
    <a name="directionOn"></a>
    <li>directionOn<br>
        Defines the meaning of <code>on</code> and 100%.
        Values can be <code>up</code> and <code>down</code>. By default the direction of <code>on</code> is mapped to <code>up</code>.<br>
        The best value might depend on the device type and personal preferences.<br>
        <br>
    </li>
    <a name="prorityLevel"></a>
    <li>prorityLevel<br>
        The priority of the commands send by FHEM.<br>
        The default value is 5. Do not change this unless you have problems and see the reading <code>lastStatusReply: PRIORITY LEVEL LOCKED</code>.<br>
        Try 3 and only if this fails 2.<br>
        <br>
    </li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br><br>
  
</ul>

=end html
=cut
