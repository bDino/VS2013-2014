package bank_access;

public abstract class ManagerImplBase {

	public abstract String createAccount(String owner,String branch);

	public static ManagerImplBase narrow_cast(Object gor) 
	{
		return null;
	}


}
