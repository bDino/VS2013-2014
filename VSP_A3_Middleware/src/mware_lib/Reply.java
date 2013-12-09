package mware_lib;

import java.io.Serializable;

public class Reply implements Serializable{

	/**
	 * Auto generated
	 */
	private static final long serialVersionUID = -1732696400448770987L;
	private String[] message;
	Exception exception;

	
	public Reply(String msg, Exception e)
	{
		message = msg.split("|");
		exception = e;
	}
	
	public Object getObject()
	{
		return (!isInvalid() ? message[1] : null);
	}

	public boolean isInvalid()
	{
		return !message[message.length -1].equalsIgnoreCase("success");
	}
	
	public Exception getException()
	{
		return (isInvalid() == true ? null : new Exception(message[4]));
	}
	
}
