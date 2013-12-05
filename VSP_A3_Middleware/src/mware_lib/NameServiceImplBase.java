package mware_lib;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;
import java.net.UnknownHostException;

// CommunikationFormat: [ClassType|ObjectName|ObjectMethod|MethodParamObjectArray|ParamClassArray|SUCCESS/ERROR]
public class NameServiceImplBase extends NameService {

	private String serviceName;
	private int port;
	private Socket socket = null;
	private InputStreamReader in;
	private OutputStream out;
	private BufferedReader bufferedReader;

	public NameServiceImplBase(String serviceName, int port) {
		this.serviceName = serviceName;
		this.port = port;
	}

	@Override
	public void rebind(Object servant, String name) {
		if (this.socket == null || this.socket.isClosed()) {
			try {
				initializeConnection();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

		try {
			out.write(new Request("Rebind|" + servant.toString() + "|" + name).toSerialized());
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private void initializeConnection() throws UnknownHostException, IOException {
		socket = new Socket(this.serviceName, this.port);
		in = new InputStreamReader(socket.getInputStream());
		out = socket.getOutputStream();
		bufferedReader = new BufferedReader(in);
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

}
