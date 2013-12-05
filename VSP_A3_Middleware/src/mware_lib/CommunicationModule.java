package mware_lib;

public class CommunicationModule {

	String hostname;
	int port;
	
	public CommunicationModule(String host, int port)
	{
		this.hostname = host;
		this.port = port;
	}
	
	public Reply invokeRemoteMethod(String msg)
	{
		return null;
	}
	
}
