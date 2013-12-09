package cash_access;

import java.util.UUID;

import bank_access.OverdraftException;
import mware_lib.CommunicationModule;
import mware_lib.Reply;

//TODO: Exceptions werfen...Overdraft!? das heißt wir müssen doch an den objekten was verändern?? ahhh...
public class TransactionImpl extends TransactionImplBase {

	String name;
	String host;
	int port;
	CommunicationModule commModule;
	
	public TransactionImpl(String name, String host, int port){
		this.name = name;
		this.host = host;
		this.port = port;
		commModule = new CommunicationModule(host, port);
	}
	
	//TODO: invalidParamException!!!
	@Override
	public void deposit(String accountId, double amount)
			throws InvalidParamException {
		
		Object[] args = new Object[]{accountId, amount};
		Class<?>[] classes = new Class[]{String.class, double.class};
		Request request = new Request(name, "deposit", args, classes);
		Reply reply = commModule.invokeRemoteMethod(request);

		if(reply.isInvalid()){
			RuntimeException e = (RuntimeException) reply.getException();
			throw e;
		}
	}

	//TODO: invalidParamException!!!
	@Override
	public void withdraw(String accountId, double amount)
			throws InvalidParamException, OverdraftException {
		
		if(getBalance(accountId) < amount) throw new cash_access.OverdraftException("Balance is lower then the amount");
		
		Object[] args = new Object[]{accountId, amount};
		Class<?>[] classes = new Class[]{String.class, double.class};
		Request request = new Request(name, "withdraw", args, classes);
		Reply reply = commModule.invokeRemoteMethod(request);
		
		if(reply.isInvalid()){
			RuntimeException e = (RuntimeException) reply.getException();
			throw e;
		}
		
		
	}

	//TODO: invalidParamException!!!
	@Override
	public double getBalance(String accountId) 
			throws InvalidParamException {
		Object[] args = new Object[]{accountId};
		Class<?>[] classes = new Class[]{String.class};
		Request request = new Request(name, "getBalance", args, classes);
		Reply reply = commModule.invokeRemoteMethod(request);
		
		if(reply.isInvalid())
		{
			RuntimeException e = (RuntimeException) reply.getException();
			throw e;
		}
		else
		{
			double value = (double) reply.getObject();
			return value;
		}
	}
	
	

}
