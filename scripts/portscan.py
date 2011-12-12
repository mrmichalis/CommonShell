#!/usr/bin/env python
from socket import *

if __name__ == '__main__':

  for target in open('smart-ip.lst', 'r'):
    targetIP = gethostbyname(target)
    print 'Starting scan on host %s ' % (targetIP,) 
    for port in open('smart-ports.lst', 'r'):
      s = socket(AF_INET, SOCK_STREAM)
      result = s.connect_ex((targetIP, int(port)))
      if(result == 0) :
          print 'Port %d: OPEN' % (int(port),)
      else:
          print 'Port %d: OPEN' % (int(port),)
      s.close()