#!/usr/bin/env python
# --------------------------------------------------------------------------
#
# 12/12/2011 Michalis
#
# used to scan IP and ports 
# Requires file "ip.lst" and "ports.lst"
#
# --------------------------------------------------------------------------
from socket import *

if __name__ == '__main__':

  for target in open('ip.lst', 'r'):
    targetIP = gethostbyname(target)
    print 'Starting scan on host %s ' % (targetIP,) 
    for port in open('ports.lst', 'r'):
      s = socket(AF_INET, SOCK_STREAM)
      result = s.connect_ex((targetIP, int(port)))
      if(result == 0) :
          print 'Port %d: OPEN' % (int(port),)
      else:
          print 'Port %d: CLOSE' % (int(port),)
      s.close()