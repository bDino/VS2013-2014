package mware_lib;

public class Argument {

	public static boolean checkArgument(Object value)
	{
		return (value != null && value.toString() != "");
	}
	
}
