package Test;

import mware_lib.NameService;
import mware_lib.ObjectBroker;
import bank_access.AccountImplBase;
import bank_access.ManagerImplBase;
import bank_access.OverdraftException;

public class TestManager {

	private static String localhostName = "localhost";
	private static int GNSPort = 9876;

	public static void main(String[] args) {
		ObjectBroker broker = ObjectBroker.init(localhostName, GNSPort);
		
		NameService ns = broker.getNameService();
		
		ns.rebind(new MyManager(), "Manager_ONE");
		ns.rebind(new MyAccount(),"Account_ONE");
		
		ManagerImplBase manager = ManagerImplBase.narrowCast(ns.resolve("Manager_ONE"));
		AccountImplBase account = AccountImplBase.narrowCast(ns.resolve("Account_ONE"));
		
		manager.createAccount("Account1", "foo");
		
	}
}

class MyAccount extends AccountImplBase{

	@Override
	public void transfer(double amount) throws OverdraftException {
		System.out.println("Transfer Called :D");	
	}

	@Override
	public double getBalance() {
		// TODO Auto-generated method stub
		return 0;
	}
	
}

class MyManager extends ManagerImplBase {
	public MyManager() {
	}

	@Override
	public String createAccount(String owner, String branch) {
		return "yea";
	}

}