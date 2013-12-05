package bank_access;

import mware_lib.CommunicationModule;
import mware_lib.Reply;

public class AccountImpl extends AccountImplBase {

	String host;
	int port;
	CommunicationModule cHelper;
	
	public AccountImpl(String host, int port){
		this.host = host;
		this.port = port;
		cHelper = new CommunicationModule(host, port);
	}
	
	@Override
	public void transfer(double amount) throws OverdraftException {
		String message = "transfer|";
		
	}

	@Override
	public double getBalance() {
		Reply answer = cHelper.invokeRemoteMethod("AccountImplBase|getBalance");
		
		return Double.parseDouble(answer.getObject().toString());
	}

}
