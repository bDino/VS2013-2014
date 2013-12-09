package mware_lib;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.reflect.Method;
import java.net.ServerSocket;
import java.net.Socket;

public class ServerListener extends Thread {
	ServerSocket socket;
	String nsName;
	int nsPort;
	ObjectBroker broker;
	LocalObjectPool objectPool;

	public ServerListener(ServerSocket socket, ObjectBroker broker,LocalObjectPool objPool) {
		this.socket = socket;
		this.broker = broker;
		this.objectPool = objPool;
	}

	@Override
	public void run() {
		while (ObjectBroker.running) {
			try {
				new WorkerThread(socket.accept()).start();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}



class WorkerThread extends Thread {
	Socket socket;

	WorkerThread(Socket s) {
		this.socket = s;
	}

	@Override
	public void run()
	{
		try {
			BufferedReader reader = new BufferedReader(new InputStreamReader(
					socket.getInputStream()));

			String[] request = reader.readLine().split("|");
			String name = request[1];
			String methodName = request[2];
			String params = request[3];
			Object s = objectPool.getLocalSkeleton(name);
			
			//Method method = s.getClass().getMethod(methodName, params.split(";"));
			//method.
			
		} catch (IOException e) {
			e.printStackTrace();
		}

	}
}

}