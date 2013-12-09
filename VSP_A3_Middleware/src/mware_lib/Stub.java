package mware_lib;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.Socket;
import java.net.UnknownHostException;

public class Stub {
	
	public String objectName;
	public String host;
	public int port;
	
	public Stub(String objectName,String host, int port){
		this.objectName = objectName;
		this.host = host;
		this.port = port;
	}
	
	public Reply delegateMethod(Request request)
	{
		Reply reply;
		try {
			Socket socket = new Socket(host, port);
			ObjectOutputStream output = new ObjectOutputStream(socket.getOutputStream());
			ObjectInputStream reader = new ObjectInputStream(socket.getInputStream());
			
			output.writeObject(request);
			
			reply = (Reply) reader.readObject();
			socket.close();
			
		} catch (UnknownHostException e) {
			reply = new Reply("",e);
		} catch (IOException e) {
			reply = new Reply("",e);
		} catch(ClassNotFoundException e){
			reply = new Reply("",e);
		}
		
		return reply;
	}

}
