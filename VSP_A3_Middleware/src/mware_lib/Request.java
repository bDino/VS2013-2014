package mware_lib;

import java.io.Serializable;

public class Request implements Serializable{

	/**
	 * 
	 */
	 static final long serialVersionUID = 8831534801757565521L;
	 private String objectName;
	 private String methodName;
	 private Object[] ary;
	 private Object[] paramAry;
	 private Class<?>[] paramClassAry;
	
	public Request(String objectName, String methodName, Object[] paramAry, Class<?>[] paramClassAry)
	{
		this.objectName = objectName;
		this.methodName = methodName;
		this.paramAry = paramAry;
		this.paramClassAry = paramClassAry;
	}
		

	public byte[] toSerialized()
	{
		return (objectName + "|" + methodName + "|" + paramAry + "|" + paramClassAry).getBytes();
	}

	public String getObjectName() {
		return objectName;
	}

	public String getMethodName() {
		return methodName;
	}

	public Object[] getAry() {
		return ary;
	}

	public Object[] getParamAry() {
		return paramAry;
	}

	public Class<?>[] getParamClassAry() {
		return paramClassAry;
	}
	
	
}
