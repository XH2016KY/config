package com.oks.dao

import com.alibaba.druid.pool.DruidDataSource
import org.springframework.context.annotation.Bean
import org.springframework.beans.factory.annotation.Value
import com.oks.dao.split.DynamicDataSource
import org.springframework.jdbc.datasource.LazyConnectionDataSourceProxy
import org.springframework.context.annotation.Configuration
import org.springframework.transaction.annotation.EnableTransactionManagement
import org.springframework.context.annotation.EnableAspectJAutoProxy
import com.oks.aop.DaoAop
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean
import org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter
import java.util.Properties
import org.springframework.data.jpa.repository.config.EnableJpaRepositories
import org.springframework.context.annotation.ComponentScan
import org.springframework.context.annotation.ComponentScans
import org.springframework.orm.jpa.JpaTransactionManager
import org.springframework.context.annotation.PropertySource
import org.springframework.context.annotation.ComponentScan.Filter
import org.springframework.context.annotation.FilterType
import javax.annotation.Resource
import org.springframework.stereotype.Service

@Configuration
@ComponentScans(#[
	@ComponentScan(value = "com.oks.repository",includeFilters = #[
		@Filter(type=FilterType.ANNOTATION,classes= #[
				Resource])]),
	@ComponentScan(value = "com.oks.service",includeFilters = #[
		@Filter(type=FilterType.ANNOTATION,classes= #[
				Service])])
])
@PropertySource(#["classpath:jdbc1.properties"])
@EnableAspectJAutoProxy
@EnableTransactionManagement
@EnableJpaRepositories(basePackages=#["com.oks.repository"])
class JpaDaoConfig {
	
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
        dynamicDataSource.targetDataSources = #{"master"->master(),"slave"->slave()} 
		dynamicDataSource
	}
	
	@Bean
	def dataSource(){
		var dataSource = new LazyConnectionDataSourceProxy
		dataSource.targetDataSource = dynamicDataSource()
		dataSource
	}

	@Bean
	def transactionManager(){
		var tx = new JpaTransactionManager
		tx.dataSource = dataSource()
		tx
	}
	
	@Bean
	def DaoAop daoAop() {
		var daoAop = new DaoAop
		daoAop
	}
	
	@Bean
	def hibernateJpaVendorAdapter() {
		return new HibernateJpaVendorAdapter
	}
	
	
	@Bean
	def entityManagerFactory() {
		var entityManagerFactory = new LocalContainerEntityManagerFactoryBean
		entityManagerFactory.dataSource = dataSource()
		entityManagerFactory.jpaVendorAdapter = hibernateJpaVendorAdapter()
		entityManagerFactory.packagesToScan = "com.oks.*"
		var jpaProperties = new Properties
		jpaProperties.setProperty("hibernate.ejb.naming_strategy","org.hibernate.cfg.ImprovedNamingStrategy")
		jpaProperties.setProperty("hibernate.dialect","org.hibernate.dialect.MySQL5InnoDBDialect")
		jpaProperties.setProperty("hibernate.show_sql","true")
		jpaProperties.setProperty("hibernate.format_sql","true")
		jpaProperties.setProperty("hibernate.hbm2ddl.auto","update")
		entityManagerFactory.jpaProperties = jpaProperties
		entityManagerFactory
	}
	
}

