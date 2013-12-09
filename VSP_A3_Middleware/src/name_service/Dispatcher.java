package name_service;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;

/*
 * 
 */
public class Dispatcher extends Thread {
	Socket socket = null;
	int port;
	String hostname;
	BufferedReader reader;
	ObjectPool objectPool;

	public Dispatcher(Socket socket, ObjectPool objectPool) {
		this.socket = socket;
		this.objectPool = objectPool;
	}

	@Override
	public void run() {
		this.hostname = socket.getInetAddress().getHostName();
		this.port = socket.getPort();

		try {
			reader = new BufferedReader(new InputStreamReader(
					socket.getInputStream()));
			handleRequest(reader.readLine());
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	synchronized void handleRequest(String request) {
		String[] requestAry = request.split("|");
		Object answer = null;

		switch (requestAry[2]) {
		case "resolve":
			answer = objectPool.resolve(requestAry[3]);
			try {
				socket.getOutputStream().write((requestAry[2].toString() + "|" + answer).getBytes());
			} catch (IOException e) {
				e.printStackTrace();
			}

		case "rebind":
			objectPool.rebind(requestAry[3], requestAry[1], socket);
		}

	}
}
