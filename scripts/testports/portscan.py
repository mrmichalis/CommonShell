#!/usr/bin/env python
# --------------------------------------------------------------------------
#
# 12/12/2011 Michalis
# quick script to perform port scanning
# used to scan IP and ports
# Requires file "ip.lst" and "ports.lst"
# 
# --------------------------------------------------------------------------
from socket import *
import sys

if __name__ == '__main__':
  print "Saving to: %s..." % sys.argv[1]
  FILE = open(str(sys.argv[1]),"w")

  for target in open('smart-ip.lst', 'r'):
    targetIP = gethostbyname(target)
    print 'Starting scan on host %s' % (targetIP,)
    FILE.writelines('Starting scan on host %s\n' % (targetIP,))
    for port in open('smart-ports.lst', 'r'):
      s = socket(AF_INET, SOCK_STREAM)
      result = s.connect_ex((targetIP, int(port)))
      if(result == 0) :
        print 'Port %d: OPEN' % (int(port),)
        FILE.writelines('Port %d: OPEN\n' % (int(port),))
      else:
        print 'Port %d: CLOSE' % (int(port),)
        FILE.writelines('Port %d: CLOSE\n' % (int(port),))
      s.close()
FILE.close()