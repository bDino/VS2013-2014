package bank_access;

import java.net.Socket;

import mware_lib.CommunicationHelper;

public class AccountImpl extends AccountImplBase {

	String host;
	String port;
	CommunicationHelper cHelper;
	
	public AccountImpl(String host, String port){
		this.host = host;
		this.port = port;
		cHelper = new CommunicationHelper(new Socket(host, port));
	}
	
	@Override
	public void transfer(double amount) throws OverdraftException {
		String message = "transfer|";
		
	}

	@Override
	public double getBalance() {
		// TODO Auto-generated method stub
		return 0;
	}

}
