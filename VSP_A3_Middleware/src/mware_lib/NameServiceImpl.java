package mware_lib;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;
import java.net.UnknownHostException;

// CommunikationFormat: [ClassType|ObjectName|ObjectMethod|MethodParamObjectArray|ParamClassArray|SUCCESS/ERROR]
public class NameServiceImpl extends NameServiceImplBase {

	String gnsServiceName;
	int gnsPort;
	int serverListenerPort;
	String serverListenerHost;
	Socket socket = null;
	InputStreamReader in;
	OutputStream out;
	BufferedReader answerReader;
	LocalObjectPool objectPool;

	public NameServiceImpl(String serviceName, int port,
			LocalObjectPool objectPool, int serverListenerPort,
			String serverListenerHost) {
		this.gnsServiceName = serviceName;
		this.gnsPort = port;
		this.objectPool = objectPool;
		this.serverListenerPort = serverListenerPort;
		this.serverListenerHost = serverListenerHost;
	}

	private void initializeConnection() throws UnknownHostException,
			IOException {
		socket = new Socket(this.gnsServiceName, this.gnsPort);
		in = new InputStreamReader(socket.getInputStream());
		out = socket.getOutputStream();
		answerReader = new BufferedReader(in);
	}

	@Override
	public void rebind(Object servant, String name) {
		System.out.println("NameServie rebind called: "
				+ servant.getClass().getSimpleName() + " - " + name);
		objectPool.rebindLocalSkeleton(name, servant);

		if (this.socket == null || this.socket.isClosed()) {
			try {
				initializeConnection();
				out.write(("rebind" + "#" + servant.getClass().getSimpleName()
						+ "#" + name + "#" + serverListenerHost + "#"
						+ serverListenerPort + "\n").getBytes());
				System.out.println(answerReader.readLine());
				closeAllConnections();
			} catch (IOException e) {
				e.printStackTrace();
				closeAllConnections();
			}
		}

	}

	@Override
	public Object resolve(String name) {
		System.out.println("NameService resolve called: - " + name);
		String[] answer = null;

		if (this.socket == null || this.socket.isClosed()) {
			try {
				initializeConnection();
				closeAllConnections();

				out.write(("resolve#" + name + "\n").getBytes());
				answer = answerReader.readLine().replace(",", "").split("#");

				closeAllConnections();
			} catch (IOException e) {
				e.printStackTrace();
				closeAllConnections();
			}

		}
		
		return new Stub(name, answer[1], Integer.parseInt(answer[2]));		
	}

	public void closeAllConnections() {
		try {
			socket.close();
			in.close();
			out.close();
		} catch (IOException e) {
			System.out
					.println("Error closing Connections: \n" + e.getMessage());
		}

	}

}
