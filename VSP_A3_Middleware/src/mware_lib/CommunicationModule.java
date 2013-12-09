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
	
	public Reply invokeRemoteMethod(String msg)
	{
		Reply reply;
		try {
			socket = new Socket(hostname, port);
			OutputStream output = socket.getOutputStream();
			reader = new BufferedReader(new InputStreamReader(
					socket.getInputStream()));
			output.write(msg.getBytes());
			
			reply = new Reply(reader.readLine()); 
			socket.close();
			
		} catch (UnknownHostException e) {
			reply = new Reply("||||"+e.getMessage());
			//e.printStackTrace();
		} catch (IOException e) {
			reply = new Reply("||||"+e.getMessage());
			//e.printStackTrace();
		}
		return reply;
	}
	
}
