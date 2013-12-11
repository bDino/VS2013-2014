package bank_access;

import mware_lib.Stub;

public abstract class ManagerImplBase {

	public abstract String createAccount(String owner,String branch);

	public static ManagerImplBase narrowCast(Object gor) 
	{
		if(gor instanceof Stub)
			return (ManagerImplBase) new ManagerImpl((Stub) gor);
		return null;
	}
	
}
