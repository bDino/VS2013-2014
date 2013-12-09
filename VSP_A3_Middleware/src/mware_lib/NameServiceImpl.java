package mware_lib;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;
import java.net.UnknownHostException;

// CommunikationFormat: [ClassType|ObjectName|ObjectMethod|MethodParamObjectArray|ParamClassArray|SUCCESS/ERROR]
public class NameServiceImpl extends NameServiceImplBase {

	String globServiceName;
	int globServicePort;
	Socket socket = null;
	InputStreamReader in;
	OutputStream out;
	BufferedReader bufferedReader;
	LocalObjectPool objectPool;

	public NameServiceImpl(String serviceName, int port,
			LocalObjectPool objectPool) {
		this.globServiceName = serviceName;
		this.globServicePort = port;
		this.objectPool = objectPool;
	}

	@Override
	public void rebind(Object servant, String name) {
		System.out.println("rebind called: " + servant.toString() + " - "
				+ name);
		objectPool.rebindLocalSkeleton(name, servant);
		// TODO: sollte das socket nicht immer wieder geschlossen und neu
		// geöffnet werden?
		// dann würde sich diese abfrage erübrigen. im resolve steht die alte
		// version
		if (this.socket == null || this.socket.isClosed()) {
			try {
				initializeConnection();
				out.write(("rebind|"+servant.getClass().getName() + "|" + name).getBytes());
				socket.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

	}

	@Override
	public Object resolve(String name) {
		System.out.println("resolve called: - " + name);
		String[] answer = null;

		if (this.socket == null || this.socket.isClosed()) {
			try {
				initializeConnection();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

		try {
			out.write(("resolve|"+name).getBytes());
			answer = bufferedReader.readLine().split("|");
			socket.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return new Stub(answer[0],answer[1],Integer.parseInt(answer[2]));
	}

	private void initializeConnection() throws UnknownHostException,
			IOException {
		socket = new Socket(this.globServiceName, this.globServicePort);
		in = new InputStreamReader(socket.getInputStream());
		out = socket.getOutputStream();
		bufferedReader = new BufferedReader(in);
	}

	// TODO
	public void close() {
		try {
			socket.close();
			in.close();
			out.close();
		} catch (IOException e) {
			e.printStackTrace();
		}

	}

}
