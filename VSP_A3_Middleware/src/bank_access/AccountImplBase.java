package bank_access;

public abstract class AccountImplBase {
	
	public abstract void transfer(double amount) throws OverdraftException;
	
	public abstract double getBalance();
	
	public static AccountImplBase narrow_cast(Object o) 
	{
		return null;
	}
}