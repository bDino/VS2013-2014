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
		return (!isInvalid() ? message[1] : null);
	}

	
	public boolean isInvalid()
	{
		return !message[message.length -1].equalsIgnoreCase("success");
	}
	
	public Exception getException()
	{
		//TODO: wenn es nicht erfolgreich ist muss die exception gegeben werden oder? also andersrum...
		return (isInvalid() == true ? null : new Exception(message[4]));
	}
	
}
