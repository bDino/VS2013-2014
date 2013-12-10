package mware_lib;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.net.ServerSocket;
import java.net.Socket;

public class ServerListener extends Thread {
	ServerSocket socket;
	String nsName;
	int nsPort;
	ObjectBroker broker;
	LocalObjectPool objectPool;

	public ServerListener(ServerSocket socket, ObjectBroker broker,
			LocalObjectPool objPool) {
		this.socket = socket;
		this.broker = broker;
		this.objectPool = objPool;
	}

	@Override
	public void run() {
		while (ObjectBroker.running) {
			try {
				System.out.println("ServerListener started on Port: "
						+ socket.getLocalPort());
				new WorkerThread(socket.accept()).start();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	private class WorkerThread extends Thread {
		Socket socket;

		WorkerThread(Socket s) {
			this.socket = s;
		}

		@Override
		public void run() {
			System.out.println("ServerListenerThread running....");
			try {
				ObjectInputStream reader = new ObjectInputStream(
						socket.getInputStream());
				
				System.out.println("ServerListener got Request\n");
				
				
				Request request = (Request) reader.readObject();
				String name = request.getObjectName();
				String methodName = request.getMethodName();
				Object[] params = request.getParamAry();
				Class<?>[] classParam = request.getParamClassAry();
				
				Object s = objectPool.getLocalSkeleton(name);

				Method method = s.getClass().getMethod(methodName, classParam);
				Object result = method.invoke(s, params);

				System.out.println("Method " + methodName + " successfully invoked on Object " + name);
				ObjectOutputStream out = new ObjectOutputStream(socket.getOutputStream());
				out.writeObject(new Reply("Success",result,null));
				
				reader.close();
				out.close();
				socket.close();
			} catch (IOException e) { e.printStackTrace();
			} catch (ClassNotFoundException e) { e.printStackTrace();
			} catch (NoSuchMethodException e) { e.printStackTrace();	
			} catch (InvocationTargetException e) { e.printStackTrace(); 
			} catch (IllegalAccessException e) { e.printStackTrace(); }		
		}
	}

}