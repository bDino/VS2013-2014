package bank_access;



import mware_lib.CommunicationModule;
import mware_lib.Reply;

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
		Reply reply = commModule.invokeRemoteMethod("ManagerImplBase|Manager|createAccount|"+args+"|"+classes);
		
		if(reply.isInvalid()){
			RuntimeException e = (RuntimeException) reply.getException();
			throw e;
		}
		else {
			//TODO: was wird hier als Rückgabe überhaupt erwartet?
			return reply.getObject().toString();
		}
	}

	
}
