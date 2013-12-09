package mware_lib;

import java.util.HashMap;
import java.util.Map;

public class LocalObjectPool {

	Map<String, Skeleton> skeletonMap = null;
	
	public LocalObjectPool()
	{
		this.skeletonMap = new HashMap<String, Skeleton>();
	}
	
	public Skeleton getLocalSkeleton(String name){
		return skeletonMap.get(name);
	}
	
	public void rebindLocalSkeleton(String name, Object ref)
	{
		skeletonMap.put(name, new Skeleton(ref));
	}
	
}
