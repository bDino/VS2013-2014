package cash_access;

import java.util.UUID;

import mware_lib.CommunicationModule;
import mware_lib.Reply;

//TODO: Exceptions werfen...Overdraft!? das heißt wir müssen doch an den objekten was verändern?? ahhh...
public class TransactionImpl extends TransactionImplBase {

	//TODO: name?!
	String host;
	int port;
	CommunicationModule commModule;
	
	public TransactionImpl(String host, int port){
		this.host = host;
		this.port = port;
		commModule = new CommunicationModule(host, port);
	}
	
	@Override
	public void deposit(String accountId, double amount)
			throws InvalidParamException {
		
		Object[] args = new Object[]{accountId, amount};
		Class[] classes = new Class[]{String.class, double.class};
		Reply reply = commModule.invokeRemoteMethod("ManagerImplBase|createAccount|"+args+"|"+classes);

		if(reply.isInvalid()){
			RuntimeException e = (RuntimeException) reply.getException();
			throw e;
		}
	}

	@Override
	public void withdraw(String accountId, double amount)
			throws InvalidParamException, OverdraftException {
		
		Object[] args = new Object[]{accountId, amount};
		Class[] classes = new Class[]{String.class, double.class};
		Reply reply = commModule.invokeRemoteMethod("ManagerImplBase|createAccount|"+args+"|"+classes);
		
		if(reply.isInvalid()){
			RuntimeException e = (RuntimeException) reply.getException();
			throw e;
		}
		//TODO: muss hier was passieren wenn es klappt?
		
	}

	@Override
	public double getBalance(String accountId) 
			throws InvalidParamException {
		Object[] args = new Object[]{accountId};
		Class[] classes = new Class[]{String.class};
		Reply reply = commModule.invokeRemoteMethod("ManagerImplBase|createAccount|"+args+"|"+classes);
		
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
