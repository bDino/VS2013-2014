package bank_access;

import mware_lib.CommunicationModule;
import mware_lib.Reply;
import mware_lib.Request;

public class AccountImpl extends AccountImplBase {

	String name;
	String host;
	int port;
	CommunicationModule cMoudule;
	
	public AccountImpl(String name,String host, int port){
		this.name = name;
		this.host = host;
		this.port = port;
		cMoudule = new CommunicationModule(host, port);
	}
	
	@Override
	public void transfer(double amount) throws OverdraftException {
		if(getBalance() < amount) throw new OverdraftException("Balance is lower then the amount");
		
		Object[] args = new Object[]{amount};
		Class<?>[] classes = new Class[]{double.class};
		Request request = new Request(name, "transfer", args, classes);
		Reply answer = cMoudule.invokeRemoteMethod(request);
		
		if(answer.isInvalid()) throw new RuntimeException(answer.getException().getMessage());
	}

	@Override
	public double getBalance() {
		Request request = new Request(name, "getBalance", new Object[]{}, new Class<?>[]{});
		Reply answer = cMoudule.invokeRemoteMethod(request);
		
		if(answer.isInvalid()) {
			throw new RuntimeException(answer.getException().getMessage());
		}
		else {
			return Double.parseDouble(answer.getObject().toString());
		}
	}

}
