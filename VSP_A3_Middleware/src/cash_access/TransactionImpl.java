package cash_access;

import mware_lib.Reply;
import mware_lib.Request;
import mware_lib.Stub;


public class TransactionImpl extends TransactionImplBase {

	Stub stub;
	
	public TransactionImpl(Stub stub){
		this.stub = stub;
	}
	
	
	@Override
	public void deposit(String accountId, double amount)
			throws InvalidParamException {
		
		Object[] args = new Object[]{accountId, amount};
		Class<?>[] classes = new Class[]{String.class, double.class};
		Request request = new Request(stub.objectName, "deposit", args, classes);
		Reply reply = stub.delegateMethod(request);

		if(reply.isInvalid()){
			Exception e = reply.getException();
			if (e instanceof InvalidParamException){
				throw new InvalidParamException(e.getMessage());
			}
			else{
				throw new RuntimeException(e.getMessage());
			}
		}
	}

	
	@Override
	public void withdraw(String accountId, double amount)
			throws InvalidParamException, OverdraftException {
		
		if(getBalance(accountId) < amount) throw new OverdraftException("Balance is lower then the amount");
		
		Object[] args = new Object[]{accountId, amount};
		Class<?>[] classes = new Class[]{String.class, double.class};
		Request request = new Request(stub.objectName, "withdraw", args, classes);
		Reply reply = stub.delegateMethod(request);
		
		if(reply.isInvalid()){
			Exception e = reply.getException();
			if (e instanceof InvalidParamException){
				throw new InvalidParamException(e.getMessage());
			}
			else{
				throw new RuntimeException(e.getMessage());
			}
		}	
	}
	

	@Override
	public double getBalance(String accountId) throws InvalidParamException {
		Object[] args = new Object[]{accountId};
		Class<?>[] classes = new Class[]{String.class};
		Request request = new Request(stub.objectName, "getBalance", args, classes);
		Reply reply = stub.delegateMethod(request);
		
		if(reply.isInvalid())
		{
			Exception e = reply.getException();
			if (e instanceof InvalidParamException){
				throw new InvalidParamException(e.getMessage());
			}
			else{
				throw new RuntimeException(e.getMessage());
			}
		}
		else
		{
			double value = Double.parseDouble(reply.getMessage());
			return value;
		}
	}
}
