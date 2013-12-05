package mware_lib;

import java.io.Serializable;

public class Reply implements Serializable{

	/**
	 * Auto generated
	 */
	private static final long serialVersionUID = -1732696400448770987L;
	private String[] message;
	
	public Reply(String msg)
	{
		message = msg.split("|");
	}
	
	public Object getObject()
	{
		return (isSuccess() == true ? message[1] : null);
	}
	
	private boolean isSuccess()
	{
		return message[message.length -1].equalsIgnoreCase("success");
	}
	
	public boolean isInvalid()
	{
		return !isSuccess();
	}
	
	public Exception getException()
	{
		return (isSuccess() == false ? null : new Exception(message[4]));
	}
	
}
