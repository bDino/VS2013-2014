package bank_access;

import java.lang.reflect.Field;


public abstract class AccountImplBase {
	
	public abstract void transfer(double amount) throws OverdraftException;
	
	public abstract double getBalance();
	
	public static AccountImplBase narrow_cast(Object o) 
	{
		String name = "";
		String host = "";
		int port = 0;
		Field[] ary  = o.getClass().getFields();
		
		for(Field f : ary)
		{
			switch(f.getName()){
				case "Name" : name = f.toString();
				case "Host" : host = f.toString();
				case "port" : port = Integer.parseInt(f.toString());
			}
		}
		
		return (AccountImplBase) new AccountImpl((Stub) o);
	}
}