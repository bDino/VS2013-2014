package bank_access;



import mware_lib.CommunicationModule;

public class ManagerImpl extends ManagerImplBase{

	//TODO: name?!
	String host;
	int port;
	CommunicationModule commModule;
	
	public ManagerImpl(String host, int port){
		this.host = host;
		this.port = port;
		commModule = new CommunicationModule(host, port);
	}
	@Override
	public String createAccount(String owner, String branch) {
		Object[] args = new Object[]{owner, branch};
		Class[] classes = new Class[]{String.class, String.class};
		commModule.invokeRemoteMethod("ManagerImplBase|Manager|createAccount|"+args+"|"+classes);
		
		return null;
	}

	
}
