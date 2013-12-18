package bank_access;

import cash_access.InvalidParamException;
import mware_lib.Reply;
import mware_lib.Request;
import mware_lib.Stub;

class AccountImpl extends AccountImplBase {

	Stub stub;

	public AccountImpl(Stub stub) {
		this.stub = stub;
	}

	// TODO
	@Override
	public void transfer(double amount) throws OverdraftException {
		if (amount < 0 && getBalance() < (amount*-1))
			throw new OverdraftException("Balance is lower then the amount");

		Object[] args = new Object[] { amount };
		Class<?>[] classes = new Class[] { double.class };
		Request request = new Request(stub.objectName, "transfer", args, classes);
		Reply answer = stub.delegateMethod(request);

		if (answer.isInvalid()){
			Exception e = answer.getException();
			if (e instanceof OverdraftException || e instanceof cash_access.OverdraftException){
				throw new OverdraftException(e.getMessage());
			}
			else{
				throw new RuntimeException(e.getMessage());
			}
		}
	}

	@Override
	public double getBalance() {
		Request request = new Request(stub.objectName, "getBalance",
				new Object[] {}, new Class<?>[] {});
		Reply answer = stub.delegateMethod(request);

		if (answer.isInvalid()) {
			throw new RuntimeException(answer.getException().getMessage());
		} else {
			return Double.parseDouble(answer.getMethodResult().toString());
		}
	}

}
