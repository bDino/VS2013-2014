package mware_lib;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;
import java.net.UnknownHostException;

public class CommunicationModule {

	String hostname;
	int port;
	NameServiceImplBase ns;
	BufferedReader reader;
	Socket socket;
	
	public CommunicationModule(String host, int port)
	{
		this.hostname = host;
		this.port = port;
		
	}
	

	
}
