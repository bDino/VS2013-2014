package mware_lib;

public class CommunicationModule {

	String hostname;
	int port;
	NameService ns;
	
	public CommunicationModule(String host, int port)
	{
		this.hostname = host;
		this.port = port;
		this.ns = ObjectBroker.init(host,port).getNameService();
	}
	
	public Reply invokeRemoteMethod(String msg)
	{
		return null;
	}
	
}
