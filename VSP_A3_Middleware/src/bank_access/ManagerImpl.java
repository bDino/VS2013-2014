package bank_access;



import mware_lib.Reply;
import mware_lib.Request;
import mware_lib.Stub;

public class ManagerImpl extends ManagerImplBase{

	Stub stub;
	
	public ManagerImpl(Stub stub){
		this.stub = stub;
	}
	@Override
	public String createAccount(String owner, String branch) {
		Object[] args = new Object[]{owner, branch};
		Class<?>[] classes = new Class[]{String.class, String.class};
		
		Request request = new Request(stub.objectName, "createAccount", args, classes);
		Reply reply = stub.delegateMethod(request);
		
		if(reply.isInvalid()){
			RuntimeException e = (RuntimeException) reply.getException();
			throw e;
		}
		else {
			return reply.getObject().toString();
		}
	}

	
}
