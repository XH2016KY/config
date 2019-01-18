package com.oks.utils

import redis.clients.jedis.JedisCluster

class RedisLockUtil {
	
	
	def static boolean  tryLock(JedisCluster jedisCluster,String key,String value,Long ttl) {
		var result = jedisCluster.set(key,value,"NX","EX",ttl);		
		return "OK".equals(result)
	}
	
	

	def static boolean releaseLock(JedisCluster jedisCluster,String key,String value) {
		if(value.equals(jedisCluster.get(key))){
			return jedisCluster.del(key)>0
		}
		return false
	}
}

