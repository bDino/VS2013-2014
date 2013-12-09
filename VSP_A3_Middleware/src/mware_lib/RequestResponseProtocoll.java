package mware_lib;

import java.io.Serializable;

//CommunikationFormat: [ClassName|ObjectName|ObjectMethod|MethodParamObjectArray|ParamClassArray|SUCCESS/ERROR]
public class RequestResponseProtocoll implements Serializable{

	/**
	 * 
	 */
	 static final long serialVersionUID = 8831534801757565521L;
	 String className;
	 String objectName;
	 String methodName;
	 Object[] ary;
	 Object[] paramAry;
	 Class<?>[] paramClassAry;
	 String successError;
	 Exception ex;
	
	public RequestResponseProtocoll(String className,String objectName, String methodName, Object[] paramAry, Class<?>[] paramClassAry, Exception ex)
	{
		this.className = className;
		this.objectName = objectName;
		this.methodName = methodName;
		this.paramAry = paramAry;
		this.paramClassAry = paramClassAry;
		this.ex = ex;
	}
	
	public RequestResponseProtocoll(String className,String name)
	{
		new RequestResponseProtocoll(className,name, "",  new Object[0], new Class<?>[0], null);
	}
	

	public byte[] toSerialized()
	{
		return (objectName + "|" + methodName + "|" + paramAry + "|" + paramClassAry).getBytes();
	}
	
	public Object getObject()
	{
		//return (!isInvalid() ? message[1] : null);
		return null;
	}

	
	public boolean isInvalid()
	{
		return !successError.equalsIgnoreCase("success");
	}
	
	public Exception getException()
	{
		//TODO: wenn es nicht erfolgreich ist muss die exception gegeben werden oder? also andersrum...
		return (isInvalid() == true ? null : ex);
	}
	
}
