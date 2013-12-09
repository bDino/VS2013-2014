package bank_access;

import mware_lib.CommunicationModule;
import mware_lib.Reply;

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
		Reply answer = cMoudule.invokeRemoteMethod("AccountImplBase|transfer|" + amount + "|");
		
		if(answer.isInvalid()) throw new RuntimeException(answer.getException().getMessage());
	}

	@Override
	public double getBalance() {
		Reply answer = cMoudule.invokeRemoteMethod("AccountImplBase|getBalance");
		
		if(answer.isInvalid()) {
			throw new RuntimeException(answer.getException().getMessage());
		}
		else {
			return Double.parseDouble(answer.getObject().toString());
		}
	}

}
