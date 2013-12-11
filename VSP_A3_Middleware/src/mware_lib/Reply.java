package mware_lib;

import java.io.Serializable;

public class Reply implements Serializable{

	/**
	 * Auto generated
	 */
	private static final long serialVersionUID = -1732696400448770987L;
	private String answer;
	Exception exception;
	Object result;
	
	public Reply(String msg,Object result, Exception e)
	{
		this.answer = msg;
		this.result = result;
		this.exception = e;
	}
	
	public String getMessage()
	{
		return answer;
	}
	
	public Object getMethodResult()
	{
		return this.result;
	}

	public boolean isInvalid()
	{
		return exception != null;
	}
	
	public Exception getException()
	{
		return exception;
	}	
}
