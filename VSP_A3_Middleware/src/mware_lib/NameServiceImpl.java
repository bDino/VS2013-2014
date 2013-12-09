package mware_lib;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;
import java.net.UnknownHostException;

// CommunikationFormat: [ClassType|ObjectName|ObjectMethod|MethodParamObjectArray|ParamClassArray|SUCCESS/ERROR]
public class NameServiceImpl extends NameServiceImplBase {

	private String globServiceName;
	private int globServicePort;
	private Socket socket = null;
	private InputStreamReader in;
	private OutputStream out;
	private BufferedReader bufferedReader;

	public NameServiceImpl(String serviceName, int port) {
		this.globServiceName = serviceName;
		this.globServicePort = port;
	}

	@Override
	public void rebind(Object servant, String name) {
		//TODO: sollte das socket nicht immer wieder geschlossen und neu geöffnet werden?
		//dann würde sich diese abfrage erübrigen. im resolve steht die alte version
		if (this.socket == null || this.socket.isClosed()) {
			try {
				initializeConnection();
				out.write(new Request("Rebind|" + servant.toString() + "|" + name).toSerialized());
				socket.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

	}

	@Override
	public Object resolve(String name) {
		Reply answer = null;

		if (this.socket == null || this.socket.isClosed()) {
			try {
				initializeConnection();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

		try {
			out.write(new Request("Resolve|" + name).toSerialized());
			answer = new Reply(bufferedReader.readLine());
		} catch (IOException e) {
			e.printStackTrace();
		}
		return answer.getObject();
	}
	
	
	private void initializeConnection() throws UnknownHostException, IOException {
		socket = new Socket(this.globServiceName, this.globServicePort);
		in = new InputStreamReader(socket.getInputStream());
		out = socket.getOutputStream();
		bufferedReader = new BufferedReader(in);
	}


}
