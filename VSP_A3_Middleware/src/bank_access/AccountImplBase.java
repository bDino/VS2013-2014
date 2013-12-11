package bank_access;

import mware_lib.Stub;


public abstract class AccountImplBase {
	
	public abstract void transfer(double amount) throws OverdraftException;
	
	public abstract double getBalance();
	
	//TODO: Exception werfen!
	public static AccountImplBase narrowCast(Object gor) 
	{
		if(gor instanceof Stub)
			return (AccountImplBase) new AccountImpl((Stub) gor);
		return null;
	}
}