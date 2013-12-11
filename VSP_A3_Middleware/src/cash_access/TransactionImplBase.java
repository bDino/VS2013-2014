package cash_access;

import mware_lib.Stub;

public abstract class TransactionImplBase {
	public abstract void deposit(String accountId, double amount) throws InvalidParamException;

	public abstract void withdraw(String accountId, double amount) throws InvalidParamException, OverdraftException;

	public abstract double getBalance(String accountId) throws InvalidParamException;

	//TODO: Exception werfen!
	public static TransactionImplBase narrowCast(Object gor) 
	{
		if(gor instanceof Stub)
			return (TransactionImplBase) new TransactionImpl((Stub) gor);
		return null;
	}
	
}