package bank_access;

import java.lang.reflect.Field;


public abstract class AccountImplBase {
	
	public abstract void transfer(double amount) throws OverdraftException;
	
	public abstract double getBalance();
	
	public static AccountImplBase narrow_cast(Object o) 
	{
		AccountImpl account = null;
		Field[] ary  = o.getClass().getFields();
		
		return null;
	}
}