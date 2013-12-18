package mware_lib;

import java.io.IOException;
import java.net.ServerSocket;

/**
 * core of the middleware: Maintains a Reference to the NameService Singleton
 */
public class ObjectBroker {

	static String gnsName;
	static int gnsPort;
	static int serverListenerPort;
	static String serverListenerHost;
	static ObjectBroker broker = null;
	static NameService nameService;
	static int gNsPort = 9876;
	static LocalObjectPool objectPool = new LocalObjectPool();
	static boolean running = true;
	static ServerListener sListener = null;

	/**
	 * @return an Implementation for a local NameService
	 */
	public NameService getNameService() {
		return nameService;
	}

	/**
	 * shuts down the process, the OjectBroker is running in terminates process
	 */
	public void shutDown() {
		ObjectBroker.running = false;
		try {
			sListener.interrupt();
		} catch(SecurityException ex) { ex.printStackTrace(); }
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
	public static ObjectBroker init(String serviceName, int port) {
		if (serviceName != "" && port != 0) {
			try {
				ServerSocket sSocket = new ServerSocket(0);
				ObjectBroker.serverListenerHost = sSocket.getInetAddress().getHostAddress();
				ObjectBroker.serverListenerPort = sSocket.getLocalPort();
				
				ObjectBroker.gnsName = serviceName;
				ObjectBroker.gnsPort = port;
				ObjectBroker.broker = (ObjectBroker.broker == null ? new ObjectBroker()
						: ObjectBroker.broker);
				nameService = (NameService) new NameServiceImpl(serviceName, port,objectPool,serverListenerPort,serverListenerHost);
			
				sListener = new ServerListener(sSocket,ObjectBroker.broker,objectPool);
				sListener.start();
			} catch (IOException e) {
				System.out.println("Error initializing the ObjectBroker" + e.getMessage());
			}

			return ObjectBroker.broker;
		}else init("localhost",gnsPort);

		return null;
	}
}
