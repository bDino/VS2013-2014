package mware_lib;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;
import java.net.UnknownHostException;

// CommunikationFormat: [ClassType|ObjectName|ObjectMethod|MethodParamObjectArray|ParamClassArray|SUCCESS/ERROR]
public class NameServiceImpl extends NameServiceImplBase 
{

	String gnsServiceName;
	int gnsPort;
	Socket socket = null;
	InputStreamReader in;
	OutputStream out;
	BufferedReader bufferedReader;
	LocalObjectPool objectPool;

	public NameServiceImpl(String serviceName, int port, LocalObjectPool objectPool) 
	{
		this.gnsServiceName = serviceName;
		this.gnsPort = port;
		this.objectPool = objectPool;
	}
	
	private void initializeConnection() throws UnknownHostException,IOException 
	{
		socket = new Socket(this.gnsServiceName, this.gnsPort);
		in = new InputStreamReader(socket.getInputStream());
		out = socket.getOutputStream();
		bufferedReader = new BufferedReader(in);
	}

	@Override
	public void rebind(Object servant, String name) 
	{
		System.out.println("rebind called: " + servant.getClass().getSimpleName() + " - "
				+ name);
		objectPool.rebindLocalSkeleton(name, servant);

		if (this.socket == null || this.socket.isClosed()) {
			try {
				initializeConnection();
				out.write(("rebind|"+servant.getClass().getName() + "|" + name + "\n").getBytes());
				System.out.println(bufferedReader.readLine());
				closeAllConnections();
			} catch (IOException e) {
				closeAllConnections();
				e.printStackTrace();
			}
		}

	}

	@Override
	public Object resolve(String name)
	{
		System.out.println("resolve called: - " + name);
		String[] answer = null;

		if (this.socket == null || this.socket.isClosed()) {
			try {
				initializeConnection();
			} catch (IOException e) {
				closeAllConnections();
				e.printStackTrace();
			}
		}

		try {
			out.write(("resolve|"+name + "\n").getBytes());
			answer = bufferedReader.readLine().split("|");
			closeAllConnections();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return new Stub(answer[0],answer[1],Integer.parseInt(answer[2]));
	}

	public void closeAllConnections() 
	{
		try {
			socket.close();
			in.close();
			out.close();
		} catch (IOException e) {
			System.out.println("Error closing Connections: \n" + e.getMessage());
		}

	}

}
