package name_service;

import java.io.IOException;
import java.net.ServerSocket;

/*
 * Server-side Client Request Handler
 */
public class GlobalNameService {

	static final int defaultPort = 16437;
	static int listenPort;
	static ObjectPool objectPool = new ObjectPool();
	static ServerSocket socket = null;
	static boolean running = true;

	public static void main(String[] args) 
	{
		if(args.length != 0){
			try{
				listenPort = Integer.parseInt(args[0]);
			}
			catch(NumberFormatException ex){
				listenPort = defaultPort;
			}
		}
		
		try {
			socket = new ServerSocket(listenPort);
			
			while (running) {
				new Dispatcher(socket.accept(),objectPool).start();
			}
		} catch (IOException e) {
			e.printStackTrace();
		}

	}

	public static void shutdown() { running = false; }

}
