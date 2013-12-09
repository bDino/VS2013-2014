package bank_access;

import java.lang.reflect.Field;

public abstract class ManagerImplBase {

	public abstract String createAccount(String owner,String branch);

	public static ManagerImplBase narrow_cast(Object gor) 
	{
		String name = "";
		String host = "";
		int port = 0;
		Field[] ary  = gor.getClass().getFields();
		
		for(Field f : ary)
		{
			switch(f.getName()){
				case "Name" : name = f.toString();
				case "Host" : host = f.toString();
				case "port" : port = Integer.parseInt(f.toString());
			}
		}
		
		return (ManagerImplBase) new ManagerImpl(host,port);
	}
	
}
