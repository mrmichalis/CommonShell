#!/usr/bin/env python
import SocketServer
import sys
import time
from datetime import date

class MyTCPHandler(SocketServer.BaseRequestHandler):
  def handle(self):
    # self.request is the TCP socket connected to the client
    self.data = self.request.recv(1024).strip()    
    print "%s [CONNECTED]> %s:%d \n" % (str(date.today()),self.client_address[0],int(server.server_address[1]))

    out=open("%s.txt" % str(server.server_address[1]), 'a' )
    out.writelines("%s [CONNECTED]> %s:%d \n" % (str(date.today()),self.client_address[0],int(server.server_address[1])))
    out.close()
    
    print self.data
    # just send back the same data, but upper-cased
    self.request.send(self.data.upper())

if __name__ == "__main__":
  if len(sys.argv)>1:
    HOST = sys.argv[1]
    PORT = int(sys.argv[2])
  else:
    print "Usage portlistener.py [BIND_IP] [PORT]"
    sys.exit(1)
  
  server = SocketServer.TCPServer((HOST, PORT), MyTCPHandler)
  # Activate the server; this will keep running until you
  # interrupt the program with Ctrl-C
  server.serve_forever()
