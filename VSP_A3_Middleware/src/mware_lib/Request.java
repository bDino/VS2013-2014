package mware_lib;

import java.io.Serializable;

public class Request implements Serializable{

	/**
	 * 
	 */
	private static final long serialVersionUID = 8831534801757565521L;
	private String message;
	
	public Request(String msg)
	{
		this.message = msg;
	}
	
	public byte[] toSerialized()
	{
		return (this.message).getBytes();
	}
}
