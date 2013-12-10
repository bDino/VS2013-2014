package Test;

import mware_lib.NameServiceImplBase;
import mware_lib.ObjectBroker;
import bank_access.ManagerImplBase;

public class TestManager {

	private static String localhostName = "localhost";
	private static int GNSPort = 16437;

	public static void main(String[] args) {
		ObjectBroker broker = ObjectBroker.init(localhostName, GNSPort);
		NameServiceImplBase ns = broker.getNameService();

		ns.rebind(new MyManager(), "Manager_ONE");
		ManagerImplBase manager = ManagerImplBase.narrow_cast(ns.resolve("Manager1"));

		manager.createAccount("Account1", "foo");

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