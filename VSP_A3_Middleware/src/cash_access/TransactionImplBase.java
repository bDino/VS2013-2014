package cash_access;

import java.lang.reflect.Field;

import bank_access.AccountImpl;
import bank_access.AccountImplBase;

public abstract class TransactionImplBase {
	public abstract void deposit(String accountId, double amount) throws InvalidParamException;

	public abstract void withdraw(String accountId, double amount) throws InvalidParamException, OverdraftException;

	public abstract double getBalance(String accountId) throws InvalidParamException;

	public static TransactionImplBase narrow_cast(Object o) 
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
		
		return (TransactionImplBase) new TransactionImpl(host,port);
	}
	
}