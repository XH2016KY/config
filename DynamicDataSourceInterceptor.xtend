package com.oks.dao.split

import org.apache.ibatis.plugin.Interceptor
import org.apache.ibatis.plugin.Invocation
import java.util.Properties
import org.apache.ibatis.executor.Executor
import org.apache.ibatis.plugin.Plugin
import org.springframework.transaction.support.TransactionSynchronizationManager
import org.apache.ibatis.mapping.MappedStatement
import org.apache.ibatis.mapping.SqlCommandType
import org.apache.ibatis.executor.keygen.SelectKeyGenerator
import java.util.Locale
import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Logger
import org.apache.ibatis.session.ResultHandler
import org.apache.ibatis.session.RowBounds
import org.apache.ibatis.plugin.Signature
import org.apache.ibatis.plugin.Intercepts

@Intercepts(#[ @Signature(type = Executor, method = "update", args = #[MappedStatement, Object ]),
		@Signature(type = Executor, method = "query", args = #[MappedStatement, Object,
				RowBounds, ResultHandler ])] )
class DynamicDataSourceInterceptor implements Interceptor {
	
	val static Logger log = LogManager.getLogger(DynamicDataSourceInterceptor)

	val static REGEX = ".*insert\\u0020.*|.*delete\\u0020.*|.*update\\u0020.*"

	override intercept(Invocation invocation) throws Throwable {
		
		var synchronizationActive = TransactionSynchronizationManager.isActualTransactionActive
		var objects = invocation.args
		var ms = objects.get(0) as MappedStatement
		var lookupKey = DynamicDataSourceHolder.DB_MASTER
		if (synchronizationActive != true) {

			
			if (ms.sqlCommandType.equals(SqlCommandType.SELECT)) {
				
				if (ms.getId().contains(SelectKeyGenerator.SELECT_KEY_SUFFIX)) {
					lookupKey = DynamicDataSourceHolder.DB_MASTER
				} else {
					var boundSql = ms.sqlSource.getBoundSql(objects.get(1))
					var sql = boundSql.sql.toLowerCase(Locale.CHINA).replaceAll("[\\t\\n\\r]", " ")
					if (sql.matches(REGEX)) {
						lookupKey = DynamicDataSourceHolder.DB_MASTER
					} else {
						lookupKey = DynamicDataSourceHolder.DB_SLAVE
					}
				}
			}
		} else {
			lookupKey = DynamicDataSourceHolder.DB_MASTER
		}
		log.info("设置方法[{}]use[{}]Strategy,SqlComman[{}]...", ms.getId(), lookupKey, ms.getSqlCommandType().name());
        DynamicDataSourceHolder.dbType = lookupKey
        invocation.proceed
	}

	override plugin(Object target) {
		// Executor CRUD
		if (target instanceof Executor)
			Plugin.wrap(target, this)
		else
			target
	}

	override setProperties(Properties properties) {
	}

}

