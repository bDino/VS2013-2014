package mware_lib;

import java.util.HashMap;
import java.util.Map;

public class LocalObjectPool {

	Map<String, Object> skeletonMap = null;
	
	public LocalObjectPool()
	{
		this.skeletonMap = new HashMap<String, Object>();
	}
	
	public Object getLocalSkeleton(String name){
		return skeletonMap.get(name);
	}
	
	public void rebindLocalSkeleton(String name, Object ref)
	{
		skeletonMap.put(name, ref);
	}
	
}
