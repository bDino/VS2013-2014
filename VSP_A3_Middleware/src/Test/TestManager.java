package Test;

import mware_lib.NameServiceImplBase;
import mware_lib.ObjectBroker;
import bank_access.ManagerImpl;
import bank_access.ManagerImplBase;

public class TestManager {
	
	private static String localhostName = "localhost";
	private static int localPort = 9856;

	public static void main(String[] args) {
		ObjectBroker broker = ObjectBroker.init("Broker",localPort);
		NameServiceImplBase ns = broker.getNameService();
		
		ns.rebind(new ManagerImpl(localhostName,localPort), "Manager1");
		
		ManagerImplBase manager = ManagerImplBase.narrow_cast(ns.resolve("Manager1"));
		
		manager.createAccount("Account1", "foo");
		
	}

}
