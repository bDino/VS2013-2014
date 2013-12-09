package cash_access;

import java.util.UUID;

import mware_lib.Stub;
import bank_access.OverdraftException;
import mware_lib.CommunicationModule;
import mware_lib.Reply;

//TODO: Exceptions werfen...Overdraft!? das heißt wir müssen doch an den objekten was verändern?? ahhh...
public class TransactionImpl extends TransactionImplBase {

	
	Stub stub;
	
	public TransactionImpl(Stub stub){
		this.stub = stub;
	}
	
	//TODO: invalidParamException!!!
	@Override
	public void deposit(String accountId, double amount)
			throws InvalidParamException {
		
		Object[] args = new Object[]{accountId, amount};
		Class<?>[] classes = new Class[]{String.class, double.class};
		Request request = new Request(name, "deposit", args, classes);
		Reply reply = stub.delegateMethod(request);

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
		Request request = new Request(stub.objectName, "withdraw", args, classes);
		Reply reply = stub.delegateMethod(request);
		
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
		Request request = new Request(stub.objectName, "getBalance", args, classes);
		Reply reply = stub.delegateMethod(request);
		
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
