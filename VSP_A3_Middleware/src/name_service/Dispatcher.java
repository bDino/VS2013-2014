package name_service;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;

//CommunikationFormat: [ClassName|ObjectName|ObjectMethod|MethodParamObjectArray|ParamClassArray|SUCCESS/ERROR]

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

		System.out.println("Dispatcher got Something from " + hostname + ", port: " + port);
		
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
		try {
			switch (requestAry[2]) {
			case "resolve":
				answer = objectPool.resolve(requestAry[3]);
				socket.getOutputStream().write((requestAry[2].toString() + "|" + answer + "\n").getBytes());
			
			case "rebind":
				boolean result = objectPool.rebind(requestAry[2], socket);
				if(result) socket.getOutputStream().write(("Success" + "\n").getBytes()) ;
				else socket.getOutputStream().write(("Error" + "\n").getBytes());
			}
		} catch (IOException e) {
			e.printStackTrace();
		}

	}
}
