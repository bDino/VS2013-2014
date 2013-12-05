package name_service;

import java.io.IOException;
import java.net.ServerSocket;

public class GlobalNameService {

	static final int listenPort = 16347;
	static ObjectPool objectPool = new ObjectPool();
	static ServerSocket socket = null;
	static boolean running = true;

	public static void main(String[] args) 
	{
		try {
			while (running) {
				socket = new ServerSocket(listenPort);
				new Dispatcher(socket.accept(),objectPool).start();
			}
		} catch (IOException e) {
			e.printStackTrace();
		}

	}

	public void shutdown() 
	{
		this.running = false;
	}

}
