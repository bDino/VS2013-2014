package mware_lib;


/**
 * core of the middleware: Maintains a Reference to the NameService Singleton
 */
public class ObjectBroker {
	
	private static String serviceName;
	private static int port;
	private static ObjectBroker broker = null;
	private static NameService nameService;
	
	/**
	 * @return an Implementation for a local NameService
	 */
	public NameService getNameService() 
	{
		return nameService;
	}

	/**
	 * shuts down the process, the OjectBroker is running in terminates process
	 */
	public void shutdown() 
	{
		ObjectBroker.broker = null;
	}

	/**
	 * Initializes the ObjectBroker / creates the local NameService
	 * 
	 * @param serviceName
	 *            hostname or IP of Nameservice
	 * @param port
	 *            port NameService is listening at
	 * @return an ObjectBroker Interface to Nameservice
	 */
	public static ObjectBroker init(String serviceName, int port) 
	{
		if(!Argument.checkArgument(serviceName) && !Argument.checkArgument(port))
		{
			ObjectBroker.serviceName = serviceName;
			ObjectBroker.port = port;
			ObjectBroker.broker = (ObjectBroker.broker == null ? new ObjectBroker() : ObjectBroker.broker);
			nameService =  new NameServiceImplBase(serviceName,port);

			return ObjectBroker.broker;
		}
		
		return null;
	}
}
