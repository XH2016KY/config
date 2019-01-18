package com.oks.mapper

import com.oks.annotation.Master
import com.oks.annotation.Slave
import com.oks.pojo.Person
import org.apache.ibatis.annotations.Mapper
import org.apache.ibatis.annotations.Param

@Mapper
interface PersonMapper {
	
	@Slave
	def Person findByName(@Param("name")String name)
	
	@Master
	def boolean addOne(@Param("person")Person person)
	
	
}


