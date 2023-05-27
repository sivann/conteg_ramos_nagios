#!/usr/bin/env perl

###############################################################################
## (c) Spiros Ioannou 2010
## version 0.1
##
## nagios plugin for CONTEG RAMOS temperature/humidity monitors. 
## This plugin uses xml values instead of SNMP because
## SNMP doesn't work through PAT/NAT routers when having multiple RAMOS in different snmp ports.
## This is a NAT restriction.
## 
## FYI: Installation of XML::Simple :
##
## shell> perl -MCPAN -e shell
## cpan> install XML::Simple
##
###############################################################################

use strict;
use warnings;
use XML::Simple;
use Data::Dumper;
use Getopt::Long;

####################################################
## Global vars
####################################################

## Initialize vars
my $host = '';
my $port = '';
my $sname = '';
my $warning  = "";
my $critical = "";
my $status="";


my %nagios_returnvalue = (
    'OK'       => 0,
    'WARNING'  => 1,
    'CRITICAL' => 2,
    'UNKNOWN'  => 3,
);

#exit $nagios_returnvalue{$status};

## Get user-supplied options
GetOptions('host=s' => \$host, 'port=s' => \$port, 'sensor=s' => \$sname, 
           'warning=s', \$warning, 'critical=s', \$critical);

if ( ($host eq '') || ($port eq '') ||  ($sname eq '') ||  ($warning eq '') || ($critical eq ''))
{
  print "\nError: Parameter missing\n";
  &Usage();
  exit(1);
}

my $server_ipport="$host:$port";

####################################################
## Main APP
####################################################

my $xml = FetchStatus($server_ipport);


my $x1 = XMLin("/tmp/$xml");

my $entries=$x1->{'SenSet'}->{'Entry'};
#print Dumper $entries->[3]->{'Name'};

my $gh;
my $found=0;
foreach  my $h (@$entries) #pointer to anonymous array of hashes
{
  if ($sname eq $h->{'Name'}) {
    $gh=$h;
    $found=1;
    last;
  }
}

if (!$found) {
  $status="UNKNOWN";
  print "$status - No data found for this sensor name\n";
  exit  $nagios_returnvalue{$status};

}

if ($gh->{'Value'} > $critical ) {
  $status="CRITICAL";
}
elsif  ($gh->{'Value'} > $warning ) {
  $status="WARNING";
}
else {
  $status="OK";
}

print "$gh->{'Name'} $status - $gh->{'Value'} $gh->{'Units'} |  $gh->{'Name'}=$gh->{'Value'}\n";

unlink("/tmp/$xml") || PrintExit("Could not delete: $!");

exit  $nagios_returnvalue{$status};


###################################################
## Subs / Functions
####################################################

## Print Usage if not all parameters are supplied
sub Usage() 
{
  print "\nUsage: check_ramos [PARAMETERS]

Parameters:
  --host=[HOSTNAME]     : IP/DNS address of nagios web interface
  --port=[port]         : PORT address of nagios web interface
  --warning=[warning]   : warning threshold
  --critical=[critical] : critical threshold
  --sensor=[name]       : RAMOS sensor name as appears on web interface\n\n";
}

## Fetch the XML from management address
sub FetchStatus
{
    ### Get the ip for connect
    my $ipport = shift;
    
    ### Generate unique output file
    my $unique = `uuidgen`;
    chomp ($unique);
    $unique .= ".xml";
    
    ### Construct URL
    my $url = "http://$ipport/values.xml";
    
    ### Fetch XML
    open(FETCH, "wget -q -O /tmp/$unique $url >/dev/null 2>&1 |") || PrintExit("Failed to run wget: $!");
    close(FETCH);

    PrintExit ("Unable to fetch status XML!") unless ( $?>>8 == 0 );
    
    ## Sleep a second
    #sleep(1);

    ## Return the fetched XML
    return $unique;
}


sub PrintExit
{
    my $msg = shift;
    print $msg."\n";
    exit 1;
}

