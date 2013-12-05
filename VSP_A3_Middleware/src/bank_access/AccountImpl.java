package bank_access;

import java.net.Socket;

import mware_lib.CommunicationModule;

public class AccountImpl extends AccountImplBase {

	String host;
	String port;
	CommunicationModule cHelper;
	
	public AccountImpl(String host, String port){
		this.host = host;
		this.port = port;
		cHelper = new CommunicationModule(new Socket(host, port));
	}
	
	@Override
	public void transfer(double amount) throws OverdraftException {
		String message = "transfer|";
		
	}

	@Override
	public double getBalance() {
		return 0;
	}

}
