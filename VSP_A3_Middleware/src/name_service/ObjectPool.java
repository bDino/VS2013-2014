package name_service;

import java.net.Socket;
import java.util.HashMap;
import java.util.Map;

public class ObjectPool {

	Map<String, Reference> stubs = new HashMap<String, Reference>();
	
	public ObjectPool(){}
	
	public synchronized void rebind(String name,Object stub, Socket socket)
	{
		System.out.println("rebind called: \nName: " + name + "\nStub: " + stub.toString() + "\nSocket: "+ socket.toString());
		stubs.put(name, new Reference(socket.getInetAddress().getHostName(), socket.getPort(),stub));
	}
	
	public synchronized Object resolve(String name)
	{
		System.out.println("resolve called: \nName: " + name);
	return stubs.get(name);
	}
	
	
	/*
	 * DS zum Speichern von Objektreferenzen
	 */
	private class Reference {
		String hostname;
		int port;
		Object stub;
		
		public Reference(String hostname, int port,Object stub) {
			this.hostname = hostname;
			this.port = port;
			this.stub = stub;
		}
	}
	
}
