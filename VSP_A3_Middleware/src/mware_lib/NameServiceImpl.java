package mware_lib;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.HashMap;
import java.util.Map;

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
				out.write(new RequestResponseProtocoll(servant.getClass()
						.getName(), name, "", new Object[0], new Class<?>[0],
						null).toSerialized());
				socket.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

	}

	@Override
	public Object resolve(String name) {
		System.out.println("resolve called: - " + name);
		Reply answer = null;

		if (this.socket == null || this.socket.isClosed()) {
			try {
				initializeConnection();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

		try {
			out.write(new RequestResponseProtocoll("Resolve|" + name)
					.toSerialized());
			answer = new Reply(bufferedReader.readLine());
		} catch (IOException e) {
			e.printStackTrace();
		}
		return answer.getObject();
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
