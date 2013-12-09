package bank_access;



import mware_lib.CommunicationModule;
import mware_lib.Reply;
import mware_lib.Request;

public class ManagerImpl extends ManagerImplBase{

	String name;
	String host;
	int port;
	CommunicationModule commModule;
	
	public ManagerImpl(String name,String host, int port){
		this.name = name;
		this.host = host;
		this.port = port;
		commModule = new CommunicationModule(host, port);
	}
	@Override
	public String createAccount(String owner, String branch) {
		Object[] args = new Object[]{owner, branch};
		Class[] classes = new Class[]{String.class, String.class};
		
		Request request = new Request(name, "createAccount", args, classes);
		Reply reply = commModule.invokeRemoteMethod(request);
		
		if(reply.isInvalid()){
			RuntimeException e = (RuntimeException) reply.getException();
			throw e;
		}
		else {
			return reply.getObject().toString();
		}
	}

	
}
