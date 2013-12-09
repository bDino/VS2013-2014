package Test;

import bank_access.ManagerImpl;
import mware_lib.NameServiceImplBase;
import mware_lib.ObjectBroker;

public class TestManager {

	public static void main(String[] args) {
		ObjectBroker broker = ObjectBroker.init("Broker",16347);
		NameServiceImplBase ns = broker.getNameService();
		
		//ns.rebind(new ManagerImpl(), "Manager1");
		
	}

}
