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
			ObjectOutputStream writer = new ObjectOutputStream(socket.getOutputStream());
			
			writer.writeObject(request);
			writer.flush();
			
			ObjectInputStream reader = new ObjectInputStream(socket.getInputStream());
			reply = (Reply) reader.readObject();
			socket.close();
			
			//System.out.println("Stub Successfull delegate Method "+ request.getMethodName()+ " with Result: " + reply.getMethodResult());
			
		} catch (UnknownHostException e) {
			reply = new Reply("",null,e);
		} catch (IOException e) {
			reply = new Reply("",null,e);
		} catch(ClassNotFoundException e){
			reply = new Reply("",null,e);
		}
		
		return reply;
	}

}
