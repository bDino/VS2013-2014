package name_service;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;
import java.util.Arrays;

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
			handleRequest(reader.readLine().replace(",",""));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	synchronized void handleRequest(String request) {
		String[] requestAry = request.split("#");
		try {
			
			System.out.println("Dispatcher Request:\n" + Arrays.deepToString(requestAry));
			
			switch (requestAry[0]) {
			case "resolve":
				System.out.println("resolve called in Dispatcher\n");
				socket.getOutputStream().write((requestAry[1].toString() + "#" + objectPool.resolve(requestAry[1]) + "\n").getBytes());
			break;
			case "rebind":
				System.out.println("rebind called in Dispatcher\nRequestAry: " + Arrays.deepToString(requestAry));
				boolean result = objectPool.rebind(requestAry[2], requestAry[3], Integer.parseInt(requestAry[4]));
				if(result) socket.getOutputStream().write(("Success" + "\n").getBytes()) ;
				else socket.getOutputStream().write(("Error" + "\n").getBytes());
			break;
			}
		} catch (IOException e) {
			e.printStackTrace();
		}

	}
}
