(c) Spiros Ioannou 2010


nagios plugin for CONTEG RAMOS temperature/humidity monitors.

This plugin uses xml values instead of SNMP because
SNMP doesn't work through PAT/NAT routers when having multiple RAMOS in different snmp ports.
This is a NAT restriction.
