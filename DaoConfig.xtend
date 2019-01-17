package com.oks.dao

import com.alibaba.druid.pool.DruidDataSource
import org.springframework.context.annotation.Bean
import org.springframework.stereotype.Component
import org.springframework.context.annotation.PropertySource
import org.springframework.beans.factory.annotation.Value
import com.oks.dao.split.DynamicDataSource
import org.springframework.jdbc.datasource.LazyConnectionDataSourceProxy
import java.util.Map
import org.springframework.context.annotation.Configuration
import org.mybatis.spring.SqlSessionFactoryBean
import org.springframework.core.io.ClassPathResource
import java.io.IOException
import org.springframework.core.io.support.PathMatchingResourcePatternResolver
import org.mybatis.spring.annotation.MapperScan

@Configuration
@Component
@PropertySource("jdbc1.properties")
@MapperScan(#["com.oks.mapper"])
class DaoConfig {
	
	@Value("${jdbc.className}")
	String className
	
	@Value("${jdbc.masterUrl}")
	String masterUrl
	
    @Value("${jdbc.slaveUrl}")
    String slaveUrl
    
	@Value("${jdbc.username}")
	String username
	
	@Value("${jdbc.password}")
	String password
	
	@Value("${mybatis_config_file}")
	String mybatisConfigFile
	
	@Value("${mapper_path}")
	String mapperPath
	
	@Value("${type_alias_path}")
	String typeAliasPath
	
	@Bean("master")
	def master() {
		var master = new DruidDataSource
		master.driverClassName = className
		master.url = masterUrl
		master.username = username
		master.password = password
		master
		
	}
	
	
	@Bean("slave")
	def slave(){
		var slave = new DruidDataSource
		slave.driverClassName = className
		slave.url = slaveUrl
		slave.username = username
		slave.password = password
		slave
	}
	
	@Bean
	def dynamicDataSource(){
		var dynamicDataSource = new DynamicDataSource
        dynamicDataSource.targetDataSources = #{"master"->master(),"slave"->slave()} as Map
		dynamicDataSource
	}
	
	@Bean
	def dataSource(){
		var dataSource = new LazyConnectionDataSourceProxy
		dataSource.targetDataSource = dynamicDataSource()
		dataSource
	}

	@Bean(name = "sqlSessionFactory")
	def SqlSessionFactoryBean createSqlSessionFactoryBean() throws IOException {
		var sqlSessionFactoryBean = new SqlSessionFactoryBean();
		sqlSessionFactoryBean.setConfigLocation(new ClassPathResource(mybatisConfigFile));
		var pathMatchingResourcePatternResolver = new PathMatchingResourcePatternResolver();
		var packageSerchPath = mapperPath;
		sqlSessionFactoryBean.setMapperLocations(pathMatchingResourcePatternResolver.getResources(packageSerchPath));
		sqlSessionFactoryBean.setDataSource(dataSource());
		sqlSessionFactoryBean.setTypeAliasesPackage("typeAliasPath");
		return sqlSessionFactoryBean;

	}
}

