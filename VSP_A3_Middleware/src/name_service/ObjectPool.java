package name_service;

import java.net.Socket;
import java.util.HashMap;
import java.util.Map;

public class ObjectPool {

	Map<String, Reference> references = new HashMap<String, Reference>();
	
	public ObjectPool(){}
	
	public synchronized boolean rebind(String name, Socket socket)
	{
		System.out.println("rebind in gns called: \nName: " + name + "\nStub: " + "\nSocket: "+ socket.toString());
		if(references.containsKey(name)) return false;
		else references.put(name, new Reference(socket.getInetAddress().getHostName(), socket.getPort()));
		
		return true;
	}
	
	public synchronized String resolve(String name)
	{
		System.out.println("resolve in gns called: \nName: " + name);
		Reference ref = references.get(name);
		return (ref.hostname + "#" + ref.port);
	}
	
	
	private class Reference {
		String hostname;
		int port;

		public Reference(String hostname, int port) {
			this.hostname = hostname;
			this.port = port;
		}
	}
	
}
