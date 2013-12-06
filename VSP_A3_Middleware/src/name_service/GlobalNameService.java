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
			//TODO: Frage: Warum muss hier immer wieder ein neues Socket erstellt werden?
			while (running) {
				socket = new ServerSocket(listenPort);
				new Dispatcher(socket.accept(),objectPool).start();
			}
		} catch (IOException e) {
			e.printStackTrace();
		}

	}

	public void shutdown() { this.running = false; }

}
