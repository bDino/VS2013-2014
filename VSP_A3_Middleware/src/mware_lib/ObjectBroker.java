package mware_lib;

import java.io.IOException;
import java.net.ServerSocket;

/**
 * core of the middleware: Maintains a Reference to the NameService Singleton
 */
public class ObjectBroker {

	static String nameServiceName;
	static int nameServicePort;
	static ObjectBroker broker = null;
	static NameServiceImplBase nameService;
	static int gNsPort = 16437;
	static int listeningPort = 9856;
	static LocalObjectPool objectPool = new LocalObjectPool();
	static boolean running = true;

	/**
	 * @return an Implementation for a local NameService
	 */
	public NameServiceImplBase getNameService() {
		return nameService;
	}

	/**
	 * shuts down the process, the OjectBroker is running in terminates process
	 */
	public void shutdown() {
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
		if (!Argument.checkArgument(serviceName)
				&& !Argument.checkArgument(port)) {
			ObjectBroker.nameServiceName = serviceName;
			ObjectBroker.nameServicePort = port;
			ObjectBroker.broker = (ObjectBroker.broker == null ? new ObjectBroker()
					: ObjectBroker.broker);
			nameService = (NameServiceImplBase) new NameServiceImpl(
					serviceName, port,objectPool);

			try {
				new ServerListener(new ServerSocket(listeningPort),ObjectBroker.broker,objectPool).start();
			} catch (IOException e) {
				e.printStackTrace();
			}

			return ObjectBroker.broker;
		}

		return null;
	}
}
